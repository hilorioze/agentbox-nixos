{lib, ...}: {
  options.agentbox = with lib;
  with types; {
    machine = mkOption {
      type = str;
    };

    proxies = mkOption {
      type = listOf str;
    };

    browser = {
      userDataDir = mkOption {
        type = str;
      };

      remoteDebuggingPort = mkOption {
        type = port;
      };
    };
  };
}
