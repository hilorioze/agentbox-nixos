# Environment

## The container

The agentbox is a systemd-nspawn container on de0, an aarch64 server. It boots a full NixOS with its own Nix store, Nix daemon and system generations; nothing of de0's store or configuration is shared. Its root survives restarts, so files the agent leaves in its home stay there.

de0 owns everything around the container: the `systemd-nspawn@<hostname>` unit, the private bridge, NAT, public routing and the age key for the agentbox's secrets. Those settings live in de0's configuration, not here, and sudo inside the agentbox can't change them.

Builds run inside the agentbox, in the Nix sandbox. nspawn covers parts of the container's `/proc`, which the kernel refuses to nest a sandbox under, so `host/features/nix/sandbox.nix` keeps an uncovered `proc` mounted at `/run/nesting/proc` for it.

## Users

| User | Purpose |
| --- | --- |
| `agent` | The agent. The runner on de0 logs in as `agent` with its own SSH key; passwordless sudo. Its systemd manager keeps running without a login, so its home services and secrets are always up. |
| `deployer` | deploy-rs. Allowed to run only the activation helper and its rollback confirmation through sudo. |
| `hilorioze` | The administrator, with a password and a hardware SSH key. |

## Repository layout

| Path | Purpose |
| --- | --- |
| `flake.nix` | Inputs, the NixOS configuration, the deploy-rs node |
| `host/default.nix` | The agentbox's name in de0's registry, hostname, domain, platform, state version |
| `host/features/` | System features, one per file under a `<group>/` directory |
| `host/users/` | Users, their SSH keys and sudo rules, and which Home Manager configuration each one gets |
| `home/agent/` | The agent's Home Manager configuration |
| `home/hilorioze/` | The administrator's Home Manager configuration |
| `home/common/` | Home Manager features both users share |
| `modules/nixos/` | Options this repository adds, such as `networking.upnp.mappings` and `agentbox.browser` |
| `overlays/` | Package overlays; `pkgs.unstablePkgs` is nixpkgs unstable |
| `tofu/dns/` | DNS records of the agentbox's zone, see [networking](networking.md) |
| `devenv.nix` | Tools and formatters of this repository |

Home Manager runs as part of the NixOS configuration; there is no separate `home-manager switch`.

The `nixos-dotfiles` input is the configuration of de0 and the rest of the infrastructure. This repository reads de0's agentbox registry from it (address, bridge, domain, SSH host key, mcpproxy port), takes mcpproxy and the patchright build of Playwright MCP from its packages, and imports the administrator's zsh configuration from it; nothing here changes it.

## Deployment

The deploy-rs node is the agentbox's domain, `<name>.agentbox.hilorioze.com`, which the tailnet's DNS resolves to the agentbox's tailnet address. Inside the agentbox that name points to `127.0.0.1` through `/etc/hosts`, and the agent's SSH config sends the agent's own key, `credentials/ssh/private-key`, to it, so `direnv exec . deploy .#<hostname>` deploys the agentbox from itself. From other machines the same command goes through the tailnet.

deploy-rs keeps the previous generation until the new one confirms over a fresh SSH connection. A system that breaks SSH or the network therefore rolls back by itself; a system that only breaks some service does not, and is fixed by deploying a corrected commit.

## MCP servers

Hermes reaches every MCP server through mcpproxy, the system service `mcpproxy` running as `agent` (`host/features/services/mcpproxy.nix`). It listens on the agentbox's bridge address at the port from de0's registry, so only de0 reaches it, and accepts only clients that send the API key `services/mcpproxy/api-key`; de0 holds the same key. Its stdio servers run as `agent` inside the agentbox and find their commands in the agent's profile and the system's.

Hermes sees mcpproxy's own tools: `retrieve_tools` finds a tool across all servers, `call_tool_read`, `call_tool_write` and `call_tool_destructive` call it, and `upstream_servers` lists, adds and removes servers. A server added or approved in mcpproxy is usable at once, without restarting Hermes.

mcpproxy owns `~/.mcpproxy/mcp_config.json` and writes to it at runtime. Before every start the service merges the servers declared in `servers` of its feature into that file by name; declare a server you keep using there and deploy, the way software is installed. A server added at runtime lives only in that file, outside the history, and stays quarantined until it is approved. The listen address, the socket and authentication come from command-line flags, so editing them in the file changes nothing.

The declared servers are Playwright MCP, which drives the browser (see below), and mcp-nixos (`nixos`), which looks up packages, NixOS, Home Manager and nix-darwin options and package versions in search.nixos.org's index and other published sources, without evaluating nixpkgs here.

## Browser

Hermes' own browser and computer-use tools are off. The agent and the people it works for share one Chromium instead, so a login or a solved captcha of one serves the other (`home/agent/features/desktop/`):

- labwc, the agent's user service `labwc`, runs on a virtual output without a screen, input devices or Xwayland, and starts the user services of the graphical session.
- Chromium, the user service `chromium`, runs in it on Wayland with its profile in `~/.local/share/chromium` and the DevTools protocol on `127.0.0.1:9222`. Its extension, uBlock Origin Lite with the cookie notice and overlay lists on, comes from the Chromium policies in `host/features/desktop/chromium.nix`.
- Chromium goes out through the SOCKS proxies at the administrator's home, on cex-nixos and then fakesynology-nixos, and takes that home's timezone through `TZ`, set in the same file. There is no direct fallback: with both proxies down pages fail to load. `host/features/network/home-proxies.nix` lists the proxies in `agentbox.proxies` and resolves their names through the tailnet.
- Playwright MCP behind mcpproxy (declared in `host/features/services/mcpproxy.nix`, which also sets the profile and the port in `agentbox.browser`) attaches to that Chromium over the DevTools protocol and works in its profile, driven through patchright, which anti-bot scripts don't detect. Unnamed screenshots and snapshots go to `~/.cache/playwright-mcp`; it reads and writes files only inside the home.
- wayvnc, the user service `wayvnc`, shows the output over VNC on `127.0.0.1:5900`.
- noVNC, the system service `novnc` (`host/features/services/novnc.nix`), serves the viewer on `127.0.0.1:6080` and passes its websocket to wayvnc.
- The agentbox's traefik serves it at `https://browser.<machine>.agentbox.hilorioze.com` after a check against de0's authentik, which lets in the agentbox's owner and authentik's admins. The viewer resizes the virtual output to its window.

When a site wants a login, a captcha or a confirmation only a person can give, the agent sends that address to the people it works for and waits until they are done.

## Tools

The agent's home has bash, git, direnv with nix-direnv, devenv, Python 3, comma and nix-index, `upnpc`, yt-dlp and gallery-dl. The repository's devenv adds deploy-rs, sops, OpenTofu with the DNS provider and the formatters behind `treefmt`.

## Downloads and shared logins

yt-dlp and gallery-dl (`home/agent/features/media/`) go out through the first of the home proxies, cex-nixos: YouTube asks de0's address to sign in. gallery-dl talks to Reddit with Chrome's TLS handshake, since Reddit blocks Python's. gallery-dl comes from nixpkgs unstable: Instagram changes its web API every few weeks, and only a recent release finds its users.

Both are logged in to sites through the cookie browsers, two Google Chromes at home, on cex-nixos and fakesynology-nixos, that hold the logins every agentbox shares. Each keeps its own sessions, so its administrators log in to every site in both, through `https://cookie-browser.cex-nixos.hilorioze.com` and `https://cookie-browser.fakesynology-nixos.hilorioze.com`, behind authentik. The user service `cookies-sync` (`home/agent/features/media/cookies.nix`) runs nixos-dotfiles' `cookie-browser-fetch`, which hilot on hel0 uses too. It fetches the cookies every five minutes into `~/.local/share/cookies.txt`, which both tools read, from `https://cookies.cex-nixos.hilorioze.com`, or from `https://cookies.fakesynology-nixos.hilorioze.com` when cex-nixos doesn't answer. It signs in as `agentbox-<machine>` with the password `credentials/cookie-browser/password` from the home's SOPS file; both hosts keep that password's hash in nixos-dotfiles.

For a site only the agentbox's own browser is logged in to, add `--cookies-from-browser chromium+basictext:~/.local/share/chromium/Default` to yt-dlp.

Hermes runs a cron job's script inside the agentbox: shell scripts through `bash`, anything else through the job's interpreter or `python3`.
