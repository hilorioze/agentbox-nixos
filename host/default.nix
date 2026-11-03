{
  # keep-sorted start
  config,
  inputs,
  outputs,
  # keep-sorted end
  ...
}: {
  imports =
    [
      # keep-sorted start
      ./features
      ./users
      # keep-sorted end
    ]
    ++ (builtins.attrValues outputs.nixosModules);

  nixpkgs = {
    overlays = [outputs.overlays.default];

    hostPlatform.system = "aarch64-linux";
  };

  boot = {
    isNspawnContainer = true; # unlike `isContainer` alone, leaves nspawn's `/proc`, `/run` and `/dev` alone, whose remount fails behind private users

    loader.initScript.enable = true; # keep `/sbin/init` on the current generation for nspawn's `Boot=yes`
  };

  agentbox.machine = "CHANGEME"; # the agentbox's name in de0's `virtualisation.agentbox.machines`

  networking = {
    hostName = "agentbox-${config.agentbox.machine}"; # the bare name reads as a person
    domain = "${config.agentbox.machine}.${inputs.nixos-dotfiles.nixosConfigurations.de0.config.virtualisation.agentbox.domain}"; # the agentbox's own zone
  };

  time.timeZone = "CHANGEME"; # the owner's, so the times the agent reads and writes are theirs

  system.stateVersion = "26.05";
}
