{
  # keep-sorted start
  config,
  inputs,
  # keep-sorted end
  ...
}: {
  sops.secrets."credentials/knot/tsig-secret".restartUnits = ["traefik.service"];

  users.users.traefik.extraGroups = [config.users.groups.dns-update.name];

  services.traefik = {
    enable = true;

    dynamicConfigOptions.http = {
      # for the `-http` router of a service whose logins or sessions must not travel readable over plain http
      middlewares.redirect-to-https.redirectScheme = {
        scheme = "https";

        permanent = true;
      };

      # de0 checks the agentbox's traefik and certificate here
      routers.traefik = {
        entryPoints = ["https"];
        rule = "Host(`traefik.${config.networking.domain}`) && Path(`/ping`)";

        service = "ping@internal";
      };
    };

    staticConfigOptions = {
      ping.manualRouting = true; # reachable only through the router to `ping@internal`, not on traefik's own entrypoint

      entryPoints = {
        # keep-sorted start block=yes newline_separated=yes numeric=yes by_regex=address\s*=\s*[^;]*?:(\d+)
        http = {
          address = ":80";

          forwardedHeaders.trustedIPs = [inputs.nixos-dotfiles.nixosConfigurations.de0.config.virtualisation.agentbox.bridge.address]; # de0 forwards plain http with the client's address in `X-Forwarded-For`
        };

        https = {
          address = ":443";

          proxyProtocol.trustedIPs = [inputs.nixos-dotfiles.nixosConfigurations.de0.config.virtualisation.agentbox.bridge.address]; # de0 passes https through with the client's address in a proxy protocol header

          http.tls = {
            certResolver = "dnsupdate";

            # request one wildcard certificate for every name of this agentbox
            domains = [
              {
                main = config.networking.domain;
                sans = ["*.${config.networking.domain}"];
              }
            ];
          };
        };
        # keep-sorted end
      };

      certificatesResolvers.dnsupdate.acme = {
        email = "hostmaster@hilorioze.com"; # without an email traefik registers a new acme account on every start

        dnsChallenge = {
          provider = "dnsupdate";

          # bypass local dns caching during ACME propagation checks
          resolvers = [
            "1.1.1.1:53"
            "1.0.0.1:53"
          ];
        };
      };
    };
  };

  systemd.services.traefik.environment = {
    LEGO_DISABLE_CNAME_SUPPORT = "true"; # the wildcard in `tofu/dns` answers `_acme-challenge` with a cname to de0 until the txt record exists

    DNSUPDATE_NAMESERVER = inputs.nixos-dotfiles.nixosConfigurations.de0.config.virtualisation.agentbox.bridge.address; # knot takes updates only from agentboxes, on their gateway

    DNSUPDATE_ZONES = config.networking.domain; # the agentbox's own zone, not one found through the wildcard

    DNSUPDATE_TSIG_KEY = config.agentbox.machine;

    DNSUPDATE_TSIG_ALGORITHM = "hmac-sha256."; # lego defaults to hmac-sha1

    DNSUPDATE_TSIG_SECRET_FILE = config.sops.secrets."credentials/knot/tsig-secret".path;
  };
}
