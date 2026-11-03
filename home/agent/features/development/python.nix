{pkgs, ...}: {
  home.packages = [pkgs.python3]; # hermes runs cron scripts without an interpreter of their own through `python3`
}
