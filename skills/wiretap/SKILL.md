---
name: wiretap
description: Passively record a Google Meet locally (no bot in the room, nothing posted to chat). Use when the user wants captions + chat captured for later reference but does NOT want Claude to participate in the meeting itself. Recordings are queryable via /operator:recap or by asking Claude directly. Takes a meet.google.com URL as the argument.
---

```!
operator wiretap "$ARGUMENTS"
```

The line above was produced by the Claude Code harness pre-executing the `!` block — operator has already run by the time you read this. Do not invoke the Bash tool to run `operator wiretap` yourself.

Read the output and respond accordingly:

- **Success** — a line shaped like `operator: joining <url> (pid 12345) — use /operator:status to check, /operator:hangup to end early`. The recorder is attaching. In your own words (don't recite verbatim), tell the user:
  - Operator is attaching as a silent recorder — no bot will appear in the meeting, nothing will be posted to chat, and the meeting participants won't know Claude is listening.
  - **Recorded locally**: captions, chat, and the participant roster are saved to the user's own machine (`~/.operator/history/`). Audio is transcribed locally too. Meeting data stays private — never leaves their laptop.
  - After this meeting (or any past one), `/operator:recap` summarizes it. The user can also ask Claude directly about any past meeting — by date, by participants ("the meeting with Alice and Bob"), or by topic.
  - `/operator:hangup` ends the recording; `/operator:status` checks whether wiretap is still running.
- **Error** — anything else (`operator is already running …`, `wiretap mode is currently macOS-only.`, `wiretap requires a Meet URL …`, etc.). Tell the user in plain conversational language what's going on — don't paste the raw line in a code block. For "already running", say something like "operator is already in a meeting — `/operator:status` to see which one, `/operator:hangup` to end it before retrying". Do not retry.

**No jargon from the operator codebase.** Operator's own user-facing strings are plain English; relay at that level.

The post-spawn note is a one-time message in this Claude Code surface only — do not repeat it on later turns. Wiretap never sends `<meet_chat>` turns (no bot in the room), so any follow-up prompts will come from the user directly in this Claude Code session.

**While a meeting is live — or has just recently ended — assume the user's questions are probably about it.** If they ask about a decision, a name, a ticket, a number, or "what did they just say?" — anything that may have come up in the room — search the meeting record first via the `operator-meeting-record` MCP (`search_meeting_record`, or `search_captions` for the live spoken transcript) before reaching for memory, Linear, or other outside tools. People usually ask about the meeting they're in without spelling it out; the user should not have to say "based on the current meeting." If a request is clearly unrelated to the meeting, handle it normally.
