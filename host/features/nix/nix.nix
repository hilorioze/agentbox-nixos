{config, ...}: {
  nix.settings = let
    inherit ((import ../../../flake.nix)) nixConfig;
  in
    {
      # keep-sorted start block=yes newline_separated=yes
      auto-optimise-store = true;

      experimental-features = [
        # keep-sorted start
        "flakes"
        "nix-command"
        # keep-sorted end
      ];

      max-free = 3 * 1024 * 1024 * 1024; # 3G

      min-free = 1 * 1024 * 1024 * 1024; # 1G; collect garbage only when a build runs low on space

      trusted-users = [
        "@wheel"

        config.users.users.deployer.name
      ];
      # keep-sorted end
    }
    // nixConfig;
}
