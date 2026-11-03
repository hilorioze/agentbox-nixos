{
  # keep-sorted start
  config,
  inputs,
  lib,
  # keep-sorted end
  ...
}: {
  # policies under `/etc/chromium`, which apply whatever profile the agent's chromium starts with
  programs.chromium = let
    uBlockOriginLite = "ddkjiahejlhfcafbddmgiahcphecmpfh";
  in {
    enable = true;

    extensions = [uBlockOriginLite]; # installed and kept updated from the chrome web store; pages without ads and trackers give playwright shorter snapshots

    extraOpts = {
      "3rdparty".extensions.${uBlockOriginLite}.rulesets = [
        # keep-sorted start
        "+annoyances-cookies" # hides cookie banners without consenting to anything
        "+annoyances-overlays"
        # keep-sorted end
      ];

      # out through the administrator's home address, which anti-bot checks trust more than de0's datacenter one
      ProxySettings = {
        ProxyMode = "fixed_servers";
        ProxyServer = lib.concatStringsSep "," config.agentbox.proxies; # chromium moves on to the next proxy only while one doesn't answer; no `direct://` at the end, so with every proxy down pages fail instead of showing de0's address
      };

      WebRtcIPHandling = "disable_non_proxied_udp"; # webrtc would otherwise show de0's address over udp, which socks doesn't carry
    };
  };

  home-manager.users.agent.systemd.user.services.chromium.Service.Environment = ["TZ=${inputs.nixos-dotfiles.nixosConfigurations.cex-nixos.config.time.timeZone}"]; # chromium has no timezone policy outside chromeos, and pages see the one from `TZ`; a timezone that doesn't match the address is a bot signal
}
