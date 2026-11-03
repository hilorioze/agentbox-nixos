{
  # keep-sorted start
  config,
  osConfig,
  outputs,
  # keep-sorted end
  ...
}: {
  sops.secrets = {
    "credentials/github/deploy-key" = {};

    "credentials/ssh/private-key" = {};
  };

  home.file.".ssh/known_hosts" = {
    force = true;

    text = ''
      github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
    '';
  };

  programs.ssh = {
    enable = true;

    enableDefaultConfig = false; # home-manager warns that its old defaults will be removed and recommends `false`

    settings = {
      "*".HostKeyAlgorithms = "ssh-ed25519";

      "github.com" = {
        IdentityFile = config.sops.secrets."credentials/github/deploy-key".path; # the deploy key opens only this agentbox's own repo
        IdentitiesOnly = true;
      };

      ${outputs.deploy.nodes.${osConfig.networking.hostName}.hostname} = {
        IdentityFile = config.sops.secrets."credentials/ssh/private-key".path; # deploy-rs connects to the agentbox itself as `deployer`
        IdentitiesOnly = true;
      };
    };
  };
}
