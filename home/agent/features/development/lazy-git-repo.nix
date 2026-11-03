{
  # keep-sorted start
  config,
  lib,
  osConfig,
  pkgs,
  # keep-sorted end
  ...
}: {
  home.activation.lazyGitRepoInit = let
    repoName = osConfig.networking.hostName;
  in ''
    repo_dir=${config.home.homeDirectory}/projects/${repoName}

    if [[ ! -d $repo_dir/.git ]]; then
      ${lib.getExe pkgs.git} init $repo_dir

      ${lib.getExe pkgs.git} -C $repo_dir remote add origin git@github.com:hilorioze/${repoName}.git
      ${lib.getExe pkgs.git} -C $repo_dir remote add upstream https://github.com/hilorioze/agentbox-nixos.git # template that every agentbox merges from
    fi
  '';
}
