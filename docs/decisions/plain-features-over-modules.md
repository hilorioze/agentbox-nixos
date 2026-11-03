# Plain features over own modules

## Status

Accepted, 2026-11-21.

## Context

mcpproxy started as a NixOS module of this repository, `services.mcpproxy`, with options for its servers, address and flags, written the way nixpkgs writes its services. Only one feature ever used it, so the options added a layer to read without letting anything else configure mcpproxy.

## Decision

A service is a plain feature under `host/features/` or `home/agent/features/`: its unit, its settings and its data live in one file. The modules in `modules/` exist only to share a value between features that couldn't reach it otherwise without hardcoding it twice, such as `agentbox.browser`, or to add a single missing option to a nixpkgs service, such as `networking.upnp.mappings`.

mcpproxy is now `host/features/services/mcpproxy.nix`, and its MCP servers are the `servers` list in that file.

## Consequences

- Each service reads top to bottom in one file, and adding an MCP server means editing that list.
- A second feature that wants to change mcpproxy edits that file instead of setting an option from elsewhere.
- When two features need the same value, it becomes an option in `modules/`, the way the browser's profile and DevTools port did: mcpproxy sets them, and the agent's Chromium reads them.
