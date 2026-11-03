{
  # keep-sorted start
  config,
  inputs,
  lib,
  osConfig,
  pkgs,
  # keep-sorted end
  ...
}: let
  cookiesFile = "${config.xdg.dataHome}/cookies.txt";
in {
  sops = {
    secrets."credentials/cookie-browser/password" = {};

    templates."credentials/cookie-browser/curlrc".content = "user = \"agentbox-${osConfig.agentbox.machine}:${config.sops.placeholder."credentials/cookie-browser/password"}\"";
  };

  # the logins of the cookie browsers at home, shared by every agentbox
  programs = {
    yt-dlp.settings.cookies = cookiesFile;

    gallery-dl.settings.extractor.cookies = cookiesFile;
  };

  systemd.user = {
    services.cookies-sync = {
      Unit = {
        After = ["sops-nix.service"];
        Wants = ["sops-nix.service"];
      };

      Service = {
        Type = "oneshot";

        # take the cookies from the first cookie browser that answers; each keeps its own logins
        ExecStart = let
          # resolve through the tailnet's dns, like the proxies on the same hosts; cex-nixos first as the steadier one
          hosts = with inputs.nixos-dotfiles.nixosConfigurations; [
            cex-nixos
            fakesynology-nixos
          ];
        in "${lib.getExe inputs.nixos-dotfiles.packages.${pkgs.stdenv.hostPlatform.system}.cookie-browser-fetch} ${cookiesFile} ${config.sops.templates."credentials/cookie-browser/curlrc".path} ${lib.concatMapStringsSep " " (host: host.config.networking.fqdn) hosts}";
      };
    };

    timers.cookies-sync = {
      Install.WantedBy = ["timers.target"];

      Timer = {
        OnActiveSec = 0;
        OnUnitActiveSec = "5min"; # google rotates its session cookies while the cookie browser has its pages open
      };
    };
  };
}
