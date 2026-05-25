---
name: dial-strict
description: Send Claude into a Google Meet in strict trigger-gated mode. Same permission flow as /operator:dial (Claude pauses to ask in chat before unapproved tools), but every prompt — including follow-ups — must include @claude. No sticky conversation window. Use when the user wants tight control over which messages reach claude (high-traffic meetings, mixed-audience calls). Takes a meet.google.com URL.
---

```!
operator dial-strict claude "$ARGUMENTS"
```

The line above was produced by the Claude Code harness pre-executing the `!` block — operator has already run by the time you read this. Do not invoke the Bash tool to run `operator dial-strict` yourself; a second invocation will hit operator's singleton guard and produce a spurious "already running" error.

Read the output and respond accordingly:

- **Success** — a line shaped like `operator: joining <url> (pid 12345) — use /operator:status to check, /operator:hangup to end early`. The meeting bot is launching in strict mode. **Say nothing.** Do not post a confirmation, a recap, or a "here's how it works" note — the user already sees operator's own `joining …` line above, and Claude introduces itself inside the meeting once a participant is present. Emit no message on success.

  Why silence matters: dial bridges this Claude Code session into the meeting via `--resume`, so the in-meeting Claude shares this session's transcript — and operator relays that transcript into the meeting chat. Any text you write here right after spawn can leak into the meeting chat on top of Claude's in-meeting intro. Staying silent on success is deliberate and is the only safe behavior.
- **Error** — anything else (`Unknown bot: …`, `operator dial is already running (pid …)`, `dial claude requires the Claude Code CLI`, etc.). This is the **only** case where you speak. Tell the user in plain conversational language what's going on — don't paste the raw line in a code block. For "already running", say something like "operator is already in a meeting — `/operator:status` to see which one, `/operator:hangup` to end it before retrying". Do not retry.

**No jargon from the operator codebase.** Operator's own user-facing strings are plain English; relay at that level.

If a later prompt arrives wrapped in `<meet_chat>…</meet_chat>`, that turn came from the meeting chat surface, not this Claude Code chat — respond to its content directly.

**When the user asks YOU directly (not a `<meet_chat>` turn) while a meeting is live — or has just recently ended — assume the question is probably about it.** If they ask about a decision, a name, a ticket, a number, or "what did they just say?" — anything that may have come up in the room — search the meeting record first via the `operator-meeting-record` MCP (`search_meeting_record`, or `search_captions` for the live spoken transcript) before reaching for memory, Linear, or other outside tools. People usually ask about the meeting they're in without spelling it out; the user should not have to say "based on the current meeting." If a request is clearly unrelated to the meeting, handle it normally.
