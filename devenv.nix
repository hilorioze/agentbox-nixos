{pkgs, ...}: {
  packages = with pkgs; [
    # keep-sorted start
    deploy-rs
    sops
    # keep-sorted end
  ];

  languages = {
    nix = {
      enable = true;

      lsp.package = pkgs.nil;
    };

    opentofu = {
      enable = true;

      package = pkgs.opentofu.withPlugins (plugins: [plugins.hashicorp_dns]);
    };
  };

  treefmt = {
    enable = true;

    config.programs = {
      # keep-sorted start block=yes newline_separated=yes
      alejandra = {
        enable = true;

        priority = 100;
      };

      deadnix.enable = true;

      keep-sorted.enable = true;

      statix.enable = true;

      terraform = {
        enable = true;

        includes = ["*.tofu"]; # missing from the default includes
      };
      # keep-sorted end
    };
  };

  git-hooks.hooks = {
    # keep-sorted start block=yes newline_separated=yes
    check-merge-conflicts = {
      enable = true;

      fail_fast = true; # abort immediately so treefmt never runs on conflicted files
    };

    # use `.editorconfig` as the single source of truth for generic file normalization
    eclint = {
      enable = true;

      types = ["text"];

      # eclint only processes the first positional path, so let it discover tracked files itself
      pass_filenames = false;

      settings.fix = true;
    };

    flake-checker.enable = true;

    pre-commit-hook-ensure-sops = {
      enable = true;

      files = "(^|/)secrets\\.yaml$"; # the default `^secrets` matches only the repo root
    };

    treefmt = {
      enable = true;

      after = ["check-merge-conflicts"];
    };
    # keep-sorted end
  };

  devcontainer = {
    enable = true;

    settings = {
      # cache `/nix` between rebuilds
      mounts = ["source=devcontainer-nix,target=/nix,type=volume"];

      onCreateCommand = ''sudo sh -c 'printf "accept-flake-config = true\n" >>/etc/nix/nix.conf' '';

      customizations.vscode.extensions = [
        # keep-sorted start
        "EditorConfig.EditorConfig"
        "jnoortheen.nix-ide"
        "mkhl.direnv"
        "opentofu.vscode-opentofu"
        # keep-sorted end
      ];
    };
  };

  # ensure generated files (like `.devcontainer/devcontainer.json`) exist before treefmt runs to prevent race conditions
  tasks."devenv:treefmt:run".after = ["devenv:files"];
}
