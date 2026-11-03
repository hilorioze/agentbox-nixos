# Shared logins come from the cookie browsers

## Status

Accepted, 2026-11-22.

## Context

yt-dlp and gallery-dl need logged-in sessions for what sites show only to an account, such as Instagram posts or age-restricted videos. The accounts are shared by every agentbox and by the administrator's own tools. Sessions don't stay still: Google rotates its session cookies while a browser has its pages open, and a copy exported once goes stale.

## Decision

A Google Chrome at the home address holds the shared logins; nixos-dotfiles declares it. It keeps the sessions alive, and only its administrators log in to it. A small service next to it reads its profile's cookies on every request and serves them as a `cookies.txt` to consumers with their own passwords. Each agentbox fetches them every five minutes and never writes them back, so every copy follows the browser's rotation.

Two such browsers run, on cex-nixos and on fakesynology-nixos, each with its own sessions. An agentbox takes the whole file from cex-nixos, the steadier host, and from fakesynology-nixos only when cex-nixos doesn't answer.

Turned down:

- Each agentbox logging in through its own browser: every owner would log in to every site, and the administrator's own tools couldn't use those sessions.
- A store that consumers write rotated cookies back to: several writers race, and the session the browser keeps rotating diverges from the stored one.
- A cookie file exported once: it lasts only until the browser rotates the session.
- One profile copied between both hosts: each browser rotates the sessions on its own, so the copies diverge and the sites sign the older one out.
- Merging the cookies of both browsers: two sessions of one account would mix in one file.
## Consequences

- One login serves every agentbox; its owner sees nothing of it.
- Every agentbox can read every shared session, so the accounts are service accounts, not anyone's personal ones.
- Requests with these cookies go out through the home address, like the logins themselves.
- Every site needs a login in both browsers; one logged in only on fakesynology-nixos serves the agentboxes only while cex-nixos is down.
- With both hosts or the tailnet down, the copy in `~/.local/share/cookies.txt` stays as it was until the next successful fetch.
