# Networking

## Addresses

The agentbox sits on de0's private bridge with the address de0's registry assigns it (`host0` in `host/features/network/networkd.nix`). de0 is its gateway and NATs its traffic to the internet; DNS goes to 1.1.1.1 directly. Agentboxes on the bridge can't reach each other, and de0 decides what reaches the agentbox, so its own firewall trusts `host0`.

## Names and DNS

The agentbox owns the zone `<name>.agentbox.hilorioze.com` (its `networking.domain`), served and DNSSEC-signed by knot on de0. The apex records come from de0's registry; everything below the apex is the agentbox's to manage.

`tofu/dns/` manages those records with OpenTofu, signing updates with the agentbox's TSIG key. Run it inside the agentbox, where `host/features/network/dns-update.nix` sets its variables, and commit `terraform.tfstate` with the change:

```sh
cd tofu/dns
direnv exec ../.. tofu init
direnv exec ../.. tofu apply
```

By default the wildcard `*.<domain>` is a CNAME to de0, so every name under the zone already leads to this agentbox. knot accepts A, AAAA, CAA, CNAME, DNAME, HTTPS, LOC, MX, NAPTR, OPENPGPKEY, SMIMEA, SRV, SSHFP, SVCB, TLSA, TXT and URI records strictly below the apex; NS, DS, SOA and DNSSEC records stay with the server. A CNAME on a name that already holds other records is ignored without an error, and tofu then reports a missing resource after create.

## Certificates

Traefik in the agentbox holds one Let's Encrypt certificate for the domain and `*.<domain>`, issued through DNS-01 against knot with the same TSIG key. The certificate stays in the agentbox; de0 never sees the private key.

The 50 new certificates a week Let's Encrypt allows are shared by all of `hilorioze.com`, so reuse the wildcard instead of issuing a certificate per name.

## Publishing a service

de0 passes every connection for the zone through to the agentbox: TLS on 443 untouched, with the client's address in a PROXY protocol v2 header, and plain HTTP on 80 with it in `X-Forwarded-For`. Traefik here trusts both only from de0's bridge address.

To publish a web service, add a Traefik router for its host name on the `https` entrypoint in a feature under `host/features/` and deploy. When its logins or sessions must not travel over plain HTTP, add a `<name>-http` router for the same host on the `http` entrypoint with the middleware `redirect-to-https` and the service `noop@internal`, as the browser has. To put it behind a login, add the middleware `oidc-login`, which asks de0's authentik; authentik needs a provider for the host name and bindings of who may pass in nixos-dotfiles first, as the browser has in `hosts/de0/features/services/authentik/agentbox-browser.yaml`. A listener without a router isn't reachable from the internet; de0 forwards only 80 and 443 and the ports mapped through UPnP.

## Ports outside HTTP

For other protocols the agentbox maps ports on de0's public address through UPnP. de0's miniupnpd hands out external ports 61000–65535, shared by all agentboxes, each mapping only to the address that requested it.

- A mapping the agentbox keeps goes into `networking.upnp.mappings`:

  ```nix
  networking.upnp.mappings = [
    {
      port = 25565;
      externalPort = 61565;
      protocol = "tcp";
    }
  ];
  ```

  Each mapping becomes a `upnp-mapping-<protocol>-<external port>` service that leases it for an hour and renews it every 15 minutes. The service fails while another agentbox holds the port.
- A one-off mapping comes from `upnpc` directly: `upnpc -n <address> <port> <external port> <protocol> <lease>` takes any free external port when the requested one is busy. `upnpc -l` lists the current mappings.

Tailscale takes one mapping itself for its direct connections.

## Tailnet

The agentbox joins the tailnet as `<hostname>` under its own tag. The ACL lets it reach itself and the other agentboxes. SSH from other machines, deploys included, comes in through the tailnet; the runner on de0 connects over the bridge. On tailnet machines the domain itself resolves to the agentbox's tailnet address, the way the servers' names under `hilorioze.com` do; in public DNS the domain itself has no address. Tailnet DNS is off, since it would turn public names under the zone into tailnet addresses the ACL closes.

The ACL also lets every agentbox reach the SOCKS proxies on cex-nixos and fakesynology-nixos, which its browser goes out through. A resolved DNS delegate sends just their names under `hilorioze.com` to the tailnet's coredns on hel0, which answers with their tailnet addresses; public DNS gives their addresses on the home LAN, which the agentbox can't reach.
