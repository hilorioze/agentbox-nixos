{osConfig, ...}: {
  programs.git = {
    enable = true;

    settings.user = {
      name = osConfig.networking.hostName;
      email = "agent@${osConfig.networking.fqdn}";
    };
  };
}
