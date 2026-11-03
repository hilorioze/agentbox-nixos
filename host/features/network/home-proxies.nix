{inputs, ...}: let
  inherit (inputs.nixos-dotfiles) nixosConfigurations;

  # the socks proxies at the administrator's home, whose residential address anti-bot checks trust more than de0's datacenter one; cex-nixos first as the steadier one
  hosts = with nixosConfigurations; [
    cex-nixos
    fakesynology-nixos
  ];
in {
  agentbox.proxies = map (host: "socks5://${host.config.networking.fqdn}:${toString host.config.services._3proxy.namedServices.agentboxes.bindPort}") hosts;

  # public dns gives the proxies' names their home lan addresses, which the agentbox can't reach, and the tailnet's coredns their tailnet addresses; a delegate, unlike link settings, outlives tailscaled clearing its link with `--accept-dns=false`
  services.resolved.dnsDelegates.home-proxies.Delegate = let
    inherit (nixosConfigurations.hel0.config) networking services;
  in {
    DNS = services.headscale.settings.dns.nameservers.split.${networking.domain};
    Domains = map (host: "~${host.config.networking.fqdn}") hosts;
  };
}
