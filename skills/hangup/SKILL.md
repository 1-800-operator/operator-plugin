---
name: hangup
description: Gracefully disconnect the running operator dial session. Use when the user wants Claude out of a meeting, wants to end the bot's attendance, or asks to hang up / disconnect / stop operator. Does NOT close Chrome or end the call for the other participants — it just detaches the bot.
---

```!
operator hangup
```

The output is one line:

- `not in a meeting` — nothing was running, no action taken.
- `hung up (N sessions)` — operator detached cleanly.

Relay it back. The dial Chrome window stays open with the user still in the meeting; only the bot's CDP attachment is gone.

**No jargon from the operator codebase.** Operator's own user-facing strings are plain English; relay at that level.
