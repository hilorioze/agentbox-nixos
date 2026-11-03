{
  # keep-sorted start
  config,
  inputs,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: let
  port = 6080;
in {
  # serves the novnc viewer and passes its websocket on to the agent's wayvnc
  systemd.services.novnc = {
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      DynamicUser = true;

      ExecStart = let
        inherit (config.home-manager.users.agent.services.wayvnc) settings;
      in
        lib.escapeShellArgs [
          (lib.getExe pkgs.python3Packages.websockify)
          "--web=${pkgs.novnc}/share/webapps/novnc"
          "--file-only"
          "127.0.0.1:${toString port}"
          "${settings.address}:${toString settings.port}"
        ];

      Restart = "on-failure";
    };
  };

  # the browser's remote view, behind authentik
  services.traefik.dynamicConfigOptions.http = {
    middlewares = {
      # the same check other hosts send to de0's authentik, through its public name since de0's own loopback address doesn't reach it from here
      oidc-login.forwardAuth.address = let
        de0Config = inputs.nixos-dotfiles.nixosConfigurations.de0.config;
      in "https://idm.${de0Config.networking.domain}${de0Config.services.traefik.staticConfigOptions.entryPoints.forward-auth.address}/outpost.goauthentik.io/auth/traefik";

      # novnc has no index page; the viewer connects on its own and resizes the virtual output to the window
      novnc-viewer.redirectRegex = {
        regex = "^https://([^/]+)/$";
        replacement = "https://\${1}/vnc.html?autoconnect=true&reconnect=true&resize=remote";
      };

      # websockify upgrades a request on any path to the vnc connection, which has no password of its own, so the unauthenticated check must never carry an upgrade
      no-upgrade.headers.customRequestHeaders.Upgrade = ""; # an empty value removes the header

      novnc-health.replacePath.path = "/vnc.html";
    };

    routers = {
      novnc-http = {
        entryPoints = ["http"];
        rule = "Host(`browser.${config.networking.domain}`)";

        middlewares = ["redirect-to-https"];

        service = "noop@internal";
      };

      novnc = {
        entryPoints = ["https"];
        rule = "Host(`browser.${config.networking.domain}`)";

        # authentik first, so not even the redirect answers without a session
        middlewares = [
          "oidc-login"
          "novnc-viewer"
        ];

        service = "novnc";
      };

      # de0's gatus checks that the viewer is served, without an authentik session
      novnc-health = {
        entryPoints = ["https"];
        rule = "Host(`browser.${config.networking.domain}`) && Path(`/health`)";

        middlewares = [
          # keep-sorted start
          "no-upgrade"
          "novnc-health"
          # keep-sorted end
        ];

        service = "novnc";
      };
    };

    services.novnc.loadBalancer.servers = [{url = "http://127.0.0.1:${toString port}";}];
  };
}
