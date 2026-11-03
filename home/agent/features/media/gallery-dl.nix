{
  # keep-sorted start
  osConfig,
  pkgs,
  # keep-sorted end
  ...
}: {
  programs.gallery-dl = {
    enable = true;

    package = pkgs.unstablePkgs.gallery-dl; # instagram changes its web api every few weeks, and gallery-dl follows within days; stable nixpkgs keeps a release that finds no instagram user

    settings.extractor = {
      proxy = builtins.head osConfig.agentbox.proxies; # the shared cookies belong to sessions logged in at home; use them from the same address

      reddit.browser = "chrome"; # reddit answers python's own tls handshake with 403 "blocked by network security", whatever the cookies and address
    };
  };
}
