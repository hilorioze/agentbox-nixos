# Agentbox

This repository declares a whole agentbox: a persistent NixOS container on de0 that belongs to its agent. The system, its services and the agent's home all come from here, and the agent changes them by editing this repository, committing, deploying and pushing.

The agent runner, Hermes, lives on de0 and reaches the agentbox over SSH as `agent`; its memory, skills and sessions stay on de0. Every command, file edit and cron script of the agent runs inside the agentbox; nothing the agent does touches de0 itself.

## Guides

- [Environment](docs/environment.md): what the agentbox is, what lives where in this repository, how a change reaches the running system, and the MCP servers and browser behind mcpproxy.
- [Networking](docs/networking.md): addresses, DNS, certificates, publishing services, UPnP and the tailnet.
- [Secrets](docs/secrets.md): SOPS files, identities and how a feature consumes a secret.
- [Decisions](docs/decisions/README.md): why things are set up the way they are, and the alternatives turned down.

Read the guide and the decisions for an area before changing it. A change that goes against a decision updates it in the same commit, and a change that picks between real alternatives records a new one.

This repository and its documentation are the agent's own. Keep them true: a change updates the guides, this file and the README wherever they describe what it changes, in the same commit, and something new gets documented where the next reader will look for it.

## The checkout

The repository lives in `~/projects/<hostname>`, where `<hostname>` is the agentbox's hostname from `host/default.nix`. Home Manager creates it empty with two remotes:

- `origin`, this agentbox's own repository on GitHub. Its deploy key, `credentials/github/deploy-key`, can read and push this repository and nothing else.
- `upstream`, the public template `agentbox-nixos` every agentbox starts from. Bring its changes in with `git fetch upstream` and a merge.

On a fresh checkout run `git fetch origin` and `git switch main` once.

## Changing the agentbox

1. Edit the configuration. Put system features in `host/features/<group>/` and the agent's home features in `home/agent/features/<group>/`; `import-tree` picks up every `.nix` file there, so there is no import list to update.
2. Format and check: `direnv exec . treefmt`, then `direnv exec . nix flake check --no-build`.
3. Commit.
4. Deploy: `direnv exec . deploy .#<hostname>`. deploy-rs builds the system here and activates it through `deployer`; if the new system breaks SSH, it rolls back on its own.
5. Push to `origin`.

Commit, deploy and push your own changes without waiting to be asked, then report what changed and whether the deployment succeeded. A successful evaluation is not a successful build, and a successful build is not an activation.

Run repository tools through `direnv exec .` from the repository root, never through `nix develop` or `nix fmt`.

## Installing software

Software the agent keeps using is declared here and deployed: a package in `home.packages` of a feature under `home/agent/features/`, a service under `host/features/`, or an MCP server in `servers` of `host/features/services/mcpproxy.nix`. Never install with `nix profile`, `nix-env`, `pip install`, `npm install -g` or similar: such installs live outside the configuration, never show up in the history, and the next agentbox built from this repository doesn't have them.

The `nixos` MCP server behind mcpproxy (mcp-nixos) looks up packages, their versions and NixOS and Home Manager options in search.nixos.org's index within seconds, while `nix search` evaluates all of nixpkgs for minutes. It defaults to the unstable channel; this repository follows the release that `system.nixos.release` names. Most services already have a NixOS module, so search their options before writing a systemd unit by hand.

For a command needed once, run it without installing anything: `, <command>` (comma finds the package in the nix-index database) or `nix shell nixpkgs#<package> --command <command>`.

## Boundaries

- `agent` has passwordless sudo inside the agentbox. That gives no rights on de0, the tailnet's Headscale, other agentboxes or anything else outside.
- Use only this agentbox's own credentials. Never look for other agents' secrets, and never put a secret into a Nix expression, a command line, a commit or a log.
- Rotating an existing credential, destroying data, or anything else that deploying the previous commit can't undo needs explicit permission first.
- Keep this agentbox's private details out of the `upstream` template; it is public.
