---
name: recap
description: Recap or summarize what happened in a past or ongoing operator meeting. Use when the user asks about a meeting they (or operator) attended — questions like "what did we discuss?", "give me a recap", "what happened in the meeting earlier?", "summarize my call with X", "what did I say about Y in the meeting?". Optionally takes a meeting slug as its argument (or omit for the most recent meeting).
---

**Action — fetch the meeting record before answering.** The desktop Claude Code app cannot see meeting @-mention turns in its own session memory (operator writes them on a separate branch of the session tree), so always go through the operator-meeting-record MCP for any meeting-recall question.

**Operator records the entire meeting to disk.** This is load-bearing: never tell the user "operator only captured the tail end" or "I only have part of the meeting." If a tool response says it's truncated, that's a *display* paging limit on this single tool call, not a capture limit on the recording. The full meeting is on disk; you just need to call again with different windowing args to see earlier portions.

Use the operator-meeting-record MCP tools as follows:

1. If `$ARGUMENTS` is empty, default to the most-recent meeting (the MCP tools pick it when `meeting_slug` is omitted). If `$ARGUMENTS` looks like a slug (alphanumeric, possibly with dashes — e.g. `oah-hvgw-pcq`), pass it as `meeting_slug`. Call `list_meetings` first only if you need to disambiguate or confirm a meeting exists.
2. For a general recap / summary intent ("recap", "summarize", "what happened"), call `list_meeting_record` with NO time window — the tool returns up to 80KB of events in one call, which fits a typical 1-hour meeting. The full meeting in one shot is the right shape for synthesis.
3. **If the response begins with `"Operator recorded the entire meeting. This response is paged…"`**, the meeting is unusually long. Call `list_meeting_record` again with `end_minutes_ago` set to the timestamp of the FIRST event in this response to walk backward through the meeting. Stitch the pages together internally before summarizing — do not tell the user "I only have the tail." Two to three paged calls cover a 2–3 hour meeting.
4. For targeted questions ("did anyone mention X?", "what did I say about Y?"), prefer `search_meeting_record` over `list_meeting_record` — it's cheaper, narrower, and won't trip the byte ceiling.
5. Synthesize a recap covering, where applicable: who participated (use `list_participants` if you need the roster, including silent attendees), key topics, decisions and commitments, open questions, and any `[☎️ Operator] running <tool>` actions worth flagging.

Do not invent content — use only what's in the record. If the record genuinely is empty or the slug doesn't exist, say so plainly and call `list_meetings` to show what's actually available.

**No jargon from the operator codebase.** Operator's own user-facing strings are plain English; relay at that level.
