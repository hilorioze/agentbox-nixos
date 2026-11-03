{
  # nix's build sandbox mounts a fresh `/proc` inside a nested user namespace, which the kernel allows only while some proc mount is fully visible; nspawn covers files in the agentbox's `/proc`, so keep an uncovered one, like lxc's nesting
  systemd.mounts = [
    {
      what = "proc";

      type = "proc";

      where = "/run/nesting/proc";
      options = "nosuid,nodev,noexec";

      mountConfig.DirectoryMode = "0700"; # keeps the uncovered proc from everyone but root; a tmpfiles rule can't do it, since mounts come up before tmpfiles runs

      wantedBy = ["multi-user.target"]; # switching starts new dependencies of active targets, not of the running nix-daemon

      before = ["nix-daemon.socket"]; # every connection probes namespace support anew, so the first build already needs the mount
    }
  ];
}
