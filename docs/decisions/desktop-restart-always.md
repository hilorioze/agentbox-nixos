# Desktop services restart always

## Status

Accepted, 2026-11-21.

## Context

labwc and Chromium end cleanly, with exit code 0, when someone picks Exit in labwc's menu or closes Chromium's last window in noVNC. With `Restart=on-failure` systemd took that as a finished job: the desktop stayed black, noVNC had nothing to show, and Playwright had no browser until the next deploy or reboot.

## Decision

The agent's user services `labwc` and `chromium` run with `Restart=always`. Nothing else in the agentbox would start them again.

## Consequences

- Closing the browser or leaving the desktop through noVNC is harmless; both come back within seconds, Chromium with the same profile and its logins.
- To stop either for real, stop the user unit with `systemctl --user stop`, which systemd doesn't restart.
