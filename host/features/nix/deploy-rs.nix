{
  # keep-sorted start
  config,
  inputs,
  outputs,
  # keep-sorted end
  ...
}: let
  deployHostname = outputs.deploy.nodes.${config.networking.hostName}.hostname;
in {
  networking.hosts."127.0.0.1" = [deployHostname]; # the agent deploys the agentbox from itself under its deploy-rs name, which the agentbox's dns doesn't resolve

  programs.ssh.knownHosts.${deployHostname}.publicKey = inputs.nixos-dotfiles.nixosConfigurations.de0.config.virtualisation.agentbox.machines.${config.agentbox.machine}.sshHostKey;
}
