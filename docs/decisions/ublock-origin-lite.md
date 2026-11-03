# uBlock Origin Lite as the only extension

## Status

Accepted, 2026-11-21.

## Context

Ads, trackers and cookie banners make Playwright's page snapshots longer and cover what the agent needs to click. The browser first had two extensions for that: uBlock Origin Lite for ads and trackers and "I still don't care about cookies" for consent banners. The latter gets rid of a banner partly by clicking its buttons, which can accept cookies.

## Decision

Chromium has one extension, uBlock Origin Lite, force-installed by policy in `host/features/desktop/chromium.nix`. The policy also turns on its `annoyances-cookies` and `annoyances-overlays` rulesets through the extension's managed storage, so it hides cookie notices and overlays without consenting to anything.

The classic uBlock Origin was not an option: it is a Manifest V2 extension, which current Chromium no longer runs.

Pinning the extension in the flake, the way nixos-dotfiles pins the crx files its ungoogled-chromium needs, was turned down. uBlock Origin Lite ships its filter lists inside the extension, so a pinned version would keep stale lists until the next lock update, and nothing here depends on its exact version. Chromium updates a force-installed extension from the store on its own.

## Consequences

- The extension is installed and updated from the Chrome Web Store and can't be removed from inside the browser.
- Consent walls that block a page until a choice is made still need a click; hiding them would leave the page unusable.
- Policy-installed extensions aren't inspectable over the DevTools protocol, so check one through `chrome://policy` and the extension's own pages instead.
