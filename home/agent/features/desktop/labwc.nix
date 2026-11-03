{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: {
  # the compositor chromium runs in, on a virtual output that wayvnc shows
  wayland.windowManager.labwc = {
    enable = true;

    xwayland.enable = false; # chromium runs on wayland itself
  };

  systemd.user = {
    # stop the session's services together with labwc, whose autostart starts them
    targets.labwc-session.Unit = {
      BindsTo = ["labwc.service"];
      After = ["labwc.service"];
    };

    # home-manager leaves starting labwc to a display manager, which the agentbox has none of
    services.labwc = {
      Install.WantedBy = ["default.target"];

      Service = {
        Environment = ["WLR_BACKENDS=headless"]; # no screen or input devices; the remote viewer brings both

        ExecStart = lib.getExe config.wayland.windowManager.labwc.package;

        Restart = "always"; # its menu's exit ends it cleanly, and nothing else would bring the desktop back
      };
    };
  };
}
