{
  nixConfig = {
    # keep-sorted start block=yes newline_separated=yes
    always-allow-substitutes = true;

    extra-substituters = [
      # https://cache.nixos.org has priority 40
      "https://nix-community.cachix.org?priority=41"
      "https://cache.thalheim.io?priority=42"
    ];

    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc="
    ];
    # keep-sorted end
  };

  inputs = {
    # keep-sorted start block=yes newline_separated=yes
    flake-parts.url = "github:hercules-ci/flake-parts";

    import-tree.url = "github:vic/import-tree";
    # keep-sorted end

    # keep-sorted start block=yes newline_separated=yes
    deploy-rs = {
      url = "github:serokell/deploy-rs";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    # keep-sorted end

    # keep-sorted start block=yes newline_separated=yes
    nix-index-database = {
      url = "github:nix-community/nix-index-database";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-dotfiles.url = "github:hilorioze/nixos-dotfiles"; # keep their inputs for binary cache

    sops-nix = {
      url = "github:Mic92/sops-nix";

      inputs.nixpkgs.follows = "nixpkgs";
    };
    # keep-sorted end
  };

  outputs = inputs @ {
    # keep-sorted start
    deploy-rs,
    flake-parts,
    nixpkgs,
    # keep-sorted end
    ...
  }: let
    inherit (nixpkgs) lib;
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["aarch64-linux"];

      flake = {config, ...}: let
        mkNixosSystem = modules:
          lib.nixosSystem {
            specialArgs = {
              inherit inputs;

              outputs = config;
            };

            inherit modules;
          };

        mkDeployNode = nixosConfiguration: let
          inherit (nixosConfiguration) pkgs;

          # keep the pinned deploy-rs lib, but use nixpkgs' cached binary to avoid rebuilding deploy-rs from source
          deployLib =
            (
              deploy-rs.overlays.default
              (
                pkgs
                // {
                  deploy-rs = {
                    inherit (pkgs) deploy-rs;
                  };
                }
              )
              pkgs
            ).deploy-rs.lib;
        in {
          hostname = nixosConfiguration.config.networking.domain; # only the tailnet's dns gives it an address, the agentbox's tailnet one, as it does for the servers' names; sshd is reachable only through the tailnet

          sshUser = nixosConfiguration.config.users.users.deployer.name;

          # reuse one authenticated connection during deployment
          sshOpts = [
            "-o"
            "ControlMaster=auto"
            "-o"
            "ControlPersist=10m"
            "-o"
            "ControlPath=~/.ssh/deploy-rs-%C"
          ];

          profiles.system = {
            user = "root";

            path = deployLib.activate.nixos nixosConfiguration;
          };
        };
      in {
        nixosModules = import ./modules/nixos;

        overlays.default = lib.composeManyExtensions (import ./overlays {inherit inputs;});

        nixosConfigurations = let
          nixosConfiguration = mkNixosSystem [./host];
        in {
          ${nixosConfiguration.config.networking.hostName} = nixosConfiguration;
        };

        deploy.nodes = lib.mapAttrs (_name: mkDeployNode) config.nixosConfigurations;
      };
    };
}
