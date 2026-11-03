# agentbox-nixos

The template every agentbox starts from: a NixOS configuration for a persistent systemd-nspawn container on de0 that an AI agent owns and manages from its own copy of this repository. de0's side (the container, bridge, DNS zone, public routing and the agent runner) lives in [nixos-dotfiles](https://github.com/hilorioze/nixos-dotfiles).

[AGENTS.md](AGENTS.md) and [docs/](docs) describe the agentbox from the inside.

## A new agentbox

1. Register the machine in de0's `virtualisation.agentbox.machines` in nixos-dotfiles: its address on the bridge, the prefix of its tailnet preauth key, its SSH host key and this flake.
2. Create the private repository `agentbox-<name>` from this one, keeping this repository as the `upstream` remote.
3. Replace every `CHANGEME` (`rg CHANGEME`): the machine name and the owner's timezone in `host/default.nix`, the age recipients in `.sops.yaml`, the runner's key in `host/users/agent.nix`, the deploy keys in `host/users/agent.nix` and `host/users/deployer.nix`, and the secrets, encrypting each `secrets.yaml` with sops afterwards.
4. Put the other halves into nixos-dotfiles' secrets. de0 gets the agentbox's age key and TSIG secret under `services/agentbox/machines/<name>/`, the agent's Telegram bot token, chat and allowed users, the runner's SSH key and the same mcpproxy API key under `services/hermes/agents/<name>/`, and its cliproxyapi key as `services/cliproxyapi/users/hermes-<name>/inference-key`. hel0 gets the bcrypt hash of the tailnet preauth key as `services/headscale/preauth-keys/agentbox-<name>/bcrypt-hash`.
5. Add the public half of the agent's `credentials/github/deploy-key` to the repository as a deploy key with write access, and give de0's bootstrap token read access to the repository's contents.
6. Add the agentbox's browser to `hosts/de0/features/services/authentik/agentbox-browser.yaml` in nixos-dotfiles, bound to its owner and to authentik's admins, and its provider to `embedded-outpost.yaml`.
