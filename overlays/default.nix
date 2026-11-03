{inputs}: [
  # must precede the local overlays that extend it
  (_final: prev: {
    unstablePkgs = import inputs.nixpkgs-unstable {
      localSystem = prev.stdenv.hostPlatform.system;

      inherit (prev) config;
    };
  })
]
