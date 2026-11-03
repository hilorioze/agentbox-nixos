{
  # keep-sorted start
  config,
  inputs,
  osConfig,
  # keep-sorted end
  ...
}: {
  imports = [inputs.sops-nix.homeManagerModules.sops];

  sops.age.keyFile = osConfig.sops.secrets."users/${config.home.username}/age-key".path;
}
