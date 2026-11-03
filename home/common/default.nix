{osConfig, ...}: {
  imports = [./features];

  home.stateVersion = osConfig.system.stateVersion;
}
