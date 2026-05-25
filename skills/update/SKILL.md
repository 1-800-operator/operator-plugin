---
name: update
description: Update the operator plugin to the latest version. Use when the user says operator is outdated, the operator bot posted a "newer version available" hint in a meeting, or anything mentions running /operator:update.
---

```!
claude plugin marketplace update 1-800-operator
```

```!
claude plugin update operator@1-800-operator
```

The two lines above were produced by the Claude Code harness pre-executing the `!` blocks — the marketplace cache was refreshed and the plugin update was attempted. Do not invoke the Bash tool to run these commands yourself.

Read both outputs and respond accordingly:

- **Both succeeded** (update applied or "already up to date"). In your own words, tell the user the plugin is now current and they need to restart Claude Code for the new version to load.
- **Either failed** (network failure, marketplace missing, install error). Relay the failure line verbatim and stop.

**No jargon from the operator codebase.** Operator's own user-facing strings are plain English; relay at that level.
