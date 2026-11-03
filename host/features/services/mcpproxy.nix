{
  # keep-sorted start
  config,
  inputs,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: let
  agent = config.home-manager.users.agent;
in {
  # the browser playwright attaches to; the agent's home starts it
  agentbox.browser = {
    userDataDir = "${agent.xdg.dataHome}/chromium";

    remoteDebuggingPort = 9222;
  };

  sops.secrets."services/mcpproxy/api-key" = {
    owner = config.users.users.agent.name;

    restartUnits = ["mcpproxy.service"];
  };

  # hermes on de0 reaches every mcp server through this one endpoint; its stdio servers run as the agent
  systemd.services.mcpproxy = {
    wantedBy = ["multi-user.target"];

    # it listens on the agentbox's address, which exists only once the network is up
    after = ["network-online.target"];
    wants = ["network-online.target"];

    # stdio servers added at runtime find their commands where the agent's login shell does
    path = [
      # keep-sorted start
      "/etc/profiles/per-user/${config.users.users.agent.name}"
      "/run/current-system/sw"
      "/run/wrappers"
      # keep-sorted end
    ];

    environment = {
      MCPPROXY_API_KEY_FILE = config.sops.secrets."services/mcpproxy/api-key".path;

      HEADLESS = "1"; # no browser to open for an oauth login

      # keep-sorted start
      MCPPROXY_DISABLE_AUTO_UPDATE = "true"; # nix updates it
      MCPPROXY_TELEMETRY = "false";
      # keep-sorted end
    };

    serviceConfig = {
      User = config.users.users.agent.name;

      # mcpproxy writes its config itself, so the declared servers are merged into it rather than replacing it
      ExecStartPre = let
        # merged into mcpproxy's own config by name, so the servers added at runtime stay
        servers = map (server:
          server
          // {
            enabled = true;

            # declared here, so neither a server nor a change of its tools on an update needs a review before they show up
            quarantined = false;
            trust_mode = "auto";
          }) [
          {
            name = "nixos";

            protocol = "stdio";

            command = lib.getExe pkgs.unstablePkgs.mcp-nixos; # stable 26.05 keeps 2.x
          }

          {
            name = "playwright";

            protocol = "stdio";

            command = lib.getExe inputs.nixos-dotfiles.legacyPackages.${pkgs.stdenv.hostPlatform.system}.playwright-mcp; # nixos-dotfiles' overlays swap its `playwright-core` for patchright, which anti-bot scripts don't detect

            args = [
              "--cdp-endpoint=http://127.0.0.1:${toString config.agentbox.browser.remoteDebuggingPort}"
              "--caps=devtools,pdf,vision"
              "--output-dir=${agent.xdg.cacheHome}/playwright-mcp" # screenshots and snapshots without an explicit name
            ];

            env.PLAYWRIGHT_MCP_USER_DATA_DIR = config.agentbox.browser.userDataDir; # without it nixpkgs' wrapper turns on isolated mode, which opens a new empty context in the browser instead of using its profile

            working_dir = agent.home.homeDirectory; # playwright resolves named files against it and keeps file access inside it
          }
        ];
      in
        lib.getExe (pkgs.writeShellApplication {
          name = "mcpproxy-merge-servers";

          runtimeInputs = [pkgs.jq];

          text = ''
            config=${agent.home.homeDirectory}/.mcpproxy/mcp_config.json

            mkdir --parents "$(dirname "$config")"

            [[ -e $config ]] || echo '{}' >"$config"

            jq --slurpfile servers ${pkgs.writeText "mcpproxy-servers.json" (builtins.toJSON servers)} '
              reduce $servers[0][] as $server (.;
                .mcpServers = (.mcpServers // [])
                  | if any(.mcpServers[]; .name == $server.name)
                    then .mcpServers |= map(if .name == $server.name then . * $server else . end)
                    else .mcpServers += [$server]
                    end)
            ' "$config" >"$config.new"

            mv "$config.new" "$config"
          '';
        });

      # flags hold the settings mcpproxy must not change in its own config
      ExecStart = let
        inherit (inputs.nixos-dotfiles.nixosConfigurations.de0.config.virtualisation.agentbox) machines mcpProxy;
      in
        lib.escapeShellArgs [
          (lib.getExe inputs.nixos-dotfiles.packages.${pkgs.stdenv.hostPlatform.system}.mcpproxy)
          "serve"
          "--listen=${machines.${config.agentbox.machine}.address}:${toString mcpProxy.port}" # de0's bridge reaches it, the internet doesn't
          "--enable-socket=false" # the socket trusts every local client without the key
          "--require-mcp-auth"
        ];

      Restart = "on-failure";
      RestartSec = 10;
    };
  };
}
