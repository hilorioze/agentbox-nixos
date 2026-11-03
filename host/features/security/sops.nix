{
  # keep-sorted start
  inputs,
  lib,
  # keep-sorted end
  ...
}: {
  imports = [inputs.sops-nix.nixosModules.sops];

  sops = {
    age = {
      keyFile = "/run/host/credentials/sops.age-key"; # de0 passes the key as an nspawn credential
      sshKeyPaths = [];
    };
    gnupg.sshKeyPaths = [];

    defaultSopsFile = lib.mkDefault ../../secrets.yaml;
  };
}
