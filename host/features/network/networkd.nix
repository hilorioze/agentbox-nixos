{
  # keep-sorted start
  config,
  inputs,
  # keep-sorted end
  ...
}: {
  networking = {
    useNetworkd = true;

    useHostResolvConf = false; # de0 resolves through its tailnet, which the agentbox can't reach

    firewall.trustedInterfaces = ["host0"]; # de0 is the edge and decides what reaches the agentbox
  };

  services.resolved.enable = true;

  systemd.network.networks."40-host0" = let
    inherit (inputs.nixos-dotfiles.nixosConfigurations.de0.config.virtualisation.agentbox) bridge machines;
  in {
    matchConfig.Name = "host0";

    address = ["${machines.${config.agentbox.machine}.address}/${toString bridge.prefixLength}"];

    gateway = [bridge.address];

    dns = [
      "1.1.1.1"
      "1.0.0.1"
    ];
  };
}
