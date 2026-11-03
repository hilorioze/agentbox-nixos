# Decisions

Each file here records one decision about this agentbox: what was chosen, what it was chosen over, and what follows from it. The configuration shows what is set; these files keep why, so a later change doesn't undo a choice without knowing what it was for.

Read the decisions for an area before changing it. A change that goes against one updates that file, or replaces it and marks the old one as superseded, in the same commit. Record a new decision whenever a change picks between real alternatives and the reason isn't obvious from the code.

Files are named by subject, not numbered, so decisions taken in an agentbox and in the `upstream` template never collide on a merge. Each one has these sections:

- **Status**: accepted, or superseded by another decision, with the date.
- **Context**: the problem and the constraints.
- **Decision**: what was chosen, and the alternatives that were turned down.
- **Consequences**: what follows, including what gets worse.

| Decision | Date |
| --- | --- |
| [Plain features over own modules](plain-features-over-modules.md) | 2026-11-21 |
| [Desktop services restart always](desktop-restart-always.md) | 2026-11-21 |
| [uBlock Origin Lite as the only extension](ublock-origin-lite.md) | 2026-11-21 |
| [The browser goes out through home](browser-through-home.md) | 2026-11-21 |
| [The browser's timezone comes from `TZ`](browser-timezone.md) | 2026-11-21 |
| [Tailnet names and DNS](tailnet-names.md) | 2026-11-21 |
| [Shared logins come from the cookie browsers](cookie-browser.md) | 2026-11-22 |
