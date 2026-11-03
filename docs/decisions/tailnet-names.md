# Tailnet names and DNS

## Status

Accepted, 2026-11-21.

## Context

Names below the agentbox's domain, `<name>.agentbox.hilorioze.com`, lead to de0, which passes on only HTTP, HTTPS and the ports mapped through UPnP; the domain itself has no address in public DNS. SSH has nothing like SNI that de0 could route by, so SSH and deploys reach the agentbox only through the tailnet.

The servers under `hilorioze.com` already work this way: their public names lead to their public or home LAN addresses, while the tailnet's DNS, hel0's coredns, answers tailnet machines with their tailnet addresses.

Tailnet DNS inside the agentbox would also turn the servers' names into tailnet addresses, most of which the ACL closes to agentboxes, while their public addresses serve the same things.

## Decision

- SSH and deploys use the agentbox's domain. hel0's coredns answers tailnet machines for it with the agentbox's tailnet address, the way it does for the servers; names below it still lead to de0. Headscale's own names under `internal` were turned down: nothing else uses them, and they would be a second naming scheme next to `hilorioze.com`.
- Tailnet DNS is off in the agentbox (`--accept-dns=false`), so names resolve publicly. Inside, the domain resolves to `127.0.0.1` through `/etc/hosts`, so the agent deploys the agentbox from itself under the same name.
- The one exception is a resolved DNS delegate for the names of the [home proxies](browser-through-home.md). It sends just those names to hel0's coredns, which answers with their tailnet addresses; public DNS would give their addresses on the home LAN, which the agentbox can't reach. A delegate, unlike settings on the tailscale link, survives tailscaled resetting that link.

## Consequences

- Machines that deploy or SSH into the agentbox need tailnet DNS, as the administrator's desktops have.
- A new agentbox gets its tailnet answer from de0's registry in nixos-dotfiles, with no change here.
- A new machine the agentbox must reach over the tailnet needs its name added to a delegate, and an ACL rule in nixos-dotfiles.
