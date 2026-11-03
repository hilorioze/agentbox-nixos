{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  options.networking.upnp.mappings = with lib;
  with types;
    mkOption {
      type = listOf (submodule ({config, ...}: {
        options = {
          port = mkOption {
            type = port;
          };

          externalPort = mkOption {
            type = port;

            default = config.port;
          };

          protocol = mkOption {
            type = enum [
              # keep-sorted start
              "tcp"
              "udp"
              # keep-sorted end
            ];
          };
        };
      }));

      default = [];
    };

  config.systemd = lib.mkMerge (map (mapping: let
      unitName = "upnp-mapping-${mapping.protocol}-${toString mapping.externalPort}";
    in {
      services.${unitName} = {
        wantedBy = ["multi-user.target"];

        after = ["network-online.target"];
        wants = ["network-online.target"];

        serviceConfig = {
          Type = "oneshot";

          ExecStart = lib.escapeShellArgs [
            (lib.getExe' pkgs.miniupnpc "upnpc")
            "-e"
            "${config.networking.hostName} ${mapping.protocol} ${toString mapping.port}"
            "-a" # keeps the declared external port and fails the unit while another agentbox holds it, where `-n` would silently map a different one
            "@" # upnpc replaces it with the address this agentbox reaches the gateway from
            mapping.port
            mapping.externalPort
            mapping.protocol
            3600 # a short lease returns the port to the shared pool within an hour after the mapping is dropped or the agentbox stops
          ];
        };
      };

      timers.${unitName} = {
        wantedBy = ["timers.target"];

        timerConfig.OnUnitActiveSec = "15min"; # renew several times per lease, so a few failed renewals don't drop the mapping
      };
    })
    config.networking.upnp.mappings);
}
