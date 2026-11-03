# The browser's timezone comes from `TZ`

## Status

Accepted, 2026-11-21.

## Context

A timezone that doesn't match the address a page sees is a common bot signal. The browser [goes out through home](browser-through-home.md), so its timezone has to be the home's. The agentbox's own timezone is a separate question: the agent works for its owner, and the times it reads and writes should be the owner's.

Chromium has no policy for its timezone outside ChromeOS. Overriding it through the DevTools protocol works per page and only while Playwright is attached.

## Decision

The `chromium` user service gets `TZ` with the proxy machines' timezone, set next to the proxy policy in `host/features/desktop/chromium.nix`. Chromium takes the timezone for pages from it.

The system timezone, `time.timeZone` in `host/default.nix`, is the owner's, set per agentbox. The template leaves it as `CHANGEME`.

## Consequences

- The browser's timezone follows the proxies, whatever the owner's is.
- Changing the system timezone doesn't change what pages see, and the other way round.
