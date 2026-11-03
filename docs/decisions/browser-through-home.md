# The browser goes out through home

## Status

Accepted, 2026-11-21.

## Context

de0's address belongs to a datacenter, and anti-bot checks treat it with suspicion: more captchas, more blocked pages. The administrator's home address is a residential one these checks trust. Two machines at home, cex-nixos and fakesynology-nixos, sit behind that one public address and run SOCKS proxies for agentboxes, reachable only through the tailnet.

## Decision

Chromium's whole traffic goes through those proxies, set by the `ProxySettings` policy in `host/features/desktop/chromium.nix`: cex-nixos first as the steadier one, fakesynology-nixos while it doesn't answer. There is no `direct://` at the end of the list, so with both down pages fail to load instead of showing de0's address.

`WebRtcIPHandling` keeps WebRTC from sending UDP outside the proxy, which would show de0's address too.

Proxying only some sites was turned down: the list would need upkeep, and a site that checks its visitor through a third-party service would see two addresses.

yt-dlp and gallery-dl go through home too, through cex-nixos alone, since each takes a single proxy: YouTube asks de0's address to sign in before it gives out a video. The rest of the agentbox, Nix included, keeps using de0's connection.

## Consequences

- Pages see the home address and, through [`TZ`](browser-timezone.md), the home timezone.
- When both proxies or the home connection are down, the browser can't load anything; that is the intended failure. yt-dlp and gallery-dl fail as soon as cex-nixos is down.
- The proxies refuse private and tailnet addresses, so the browser can't open pages on the home network, and nothing in the agentbox reaches the home network through them.
- Every agentbox goes out through the same home address; the tailnet ACL in nixos-dotfiles lets all of them reach the proxies.
