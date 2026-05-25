---
name: doctor
description: Run operator's diagnostic check. Use when the user is troubleshooting operator, just installed it, or anything in the dial flow appears broken — verifies that the claude CLI, Chrome, git, and macOS TCC permissions are all set up correctly.
---

```!
operator doctor || true
```

Read the output and respond accordingly:

- **Every check green and no `Last meeting failure` section:** tell the user operator is ready.
- **A check fails:** summarize the failure and quote the operator doctor remediation hint verbatim.
- **A `Last meeting failure` section is present** (printed after the checklist): interpret it for the user in plain language. The section is a structured dump — exception class, message, phase (`boot` or `turn`), PTY tail, recent log lines. Read the `message` and `pty_tail` to figure out what actually went wrong, then say so in one or two sentences and recommend a next step. Common shapes:
  - `phase: boot` + a `message` mentioning the boot ceiling → claude took too long to start up (often a very large resumed session or a slow MCP server). Suggest re-running `/operator:dial`, or checking `claude mcp list` if it keeps happening.
  - `phase: boot` + `exited during startup (rc=…)` → claude crashed at startup; the PTY tail usually says why (auth issue, version mismatch, etc.). Quote the relevant PTY line.
  - `phase: turn` + a timeout message → claude was running on one turn for >10 minutes, likely a tool wedged. Suggest `/operator:hangup` and rejoin.
  - Anything else → use the `message` and `pty_tail` to figure it out; if the signals don't add up to a clear cause, say so honestly.
  - If a pre-flight check also failed (e.g. `claude auth`), tie that to the meeting failure as the likely root cause and lead with the pre-flight fix.

**No jargon from the operator codebase.** Operator's own user-facing strings are plain English; relay at that level.
