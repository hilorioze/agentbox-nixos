{
  # keep-sorted start
  config,
  lib,
  osConfig,
  pkgs,
  # keep-sorted end
  ...
}: {
  # playwright drives it over the devtools protocol while novnc shows it, so both work in one profile
  systemd.user.services.chromium = {
    Unit = {
      After = [config.wayland.systemd.target];
      PartOf = [config.wayland.systemd.target];
    };

    Install.WantedBy = [config.wayland.systemd.target];

    Service = {
      ExecStart = lib.escapeShellArgs [
        (lib.getExe pkgs.chromium)
        "--ozone-platform=wayland" # labwc runs without xwayland
        "--user-data-dir=${osConfig.agentbox.browser.userDataDir}"
        "--remote-debugging-port=${toString osConfig.agentbox.browser.remoteDebuggingPort}" # on loopback only
        "--start-maximized"
      ];

      Restart = "always"; # closing its last window ends it cleanly, and the agent needs it running
    };
  };
}
