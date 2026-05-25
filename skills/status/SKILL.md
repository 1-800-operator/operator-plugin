---
name: status
description: Check whether operator is currently in a Google Meet. Use when the user asks if operator is running, which meeting it's in, or whether the bot is still attached.
---

```!
operator status
```

This is a **state check, not a diagnostic.** The output reports operator's current attachment state — nothing more. Don't speculate about why operator is or isn't in a meeting; if the user wants a diagnostic, that's `/operator:doctor`.

Read the output and respond in plain language — conversational, not robotic. Don't quote the raw line back verbatim.

- `not in a meeting` → operator isn't attached to any call right now. Say so naturally ("operator's not in a meeting", "no active session", "nothing running"). **Do NOT infer failure** — this is just the steady state. It could mean operator never joined, the user `/operator:hangup`'d, the meeting ended cleanly, or any number of normal outcomes. If the user just got off a meeting and is asking about it, the right next step is `/operator:recap`, not speculation about whether the bot disconnected.
- `in meeting <url>` → operator is currently sitting in the meeting at `<url>`. Mention the URL once so the user knows which meeting, but don't read it like a label ("operator's in <url>" is fine; "Status: in meeting URL: <url>" is not). If the URL is long, you can shorten the description (e.g. "operator is in a Meet call right now — <url>").

**No jargon from the operator codebase.** Operator's own user-facing strings are plain English; relay at that level.
