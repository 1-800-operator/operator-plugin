#!/usr/bin/env bash
# Stop hook — fires when claude finishes a turn. Appends the hook
# payload (which includes last_assistant_message, session_id,
# transcript_path) as JSONL to replies.jsonl. The operator provider
# tails this file: a new row === a new meeting reply ready to post.
#
# Failure handling per the operator hook contract (see _common.sh):
# always exit 0, AND always emit at least one row to replies.jsonl
# even on internal failure. Operator's tail loop hangs at the per-
# turn timeout (default 600s) if no row appears, so a degraded
# {kind:"crashed"} row is far better than silence — it lets the
# turn end and the provider surface a clean error instead of timing
# out as if inner-claude had wedged.
. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

INPUT="$(cat)"
TS="$(ts_now)"

# Build the JSONL row in a single python invocation — same shape
# the provider has always parsed:
#   happy path:    {"ts":<float>, "kind":"stop", "input":<parsed>}
#   bad-JSON path: {"ts":<float>, "kind":"raw",  "raw":"<bytes>"}
# Any python failure falls through to the last-ditch crashed row.
ROW="$(printf '%s' "$INPUT" | python3 -c '
import json, sys
ts = float(sys.argv[1])
raw = sys.stdin.read()
try:
    parsed = json.loads(raw)
    out = {"ts": ts, "kind": "stop", "input": parsed}
except Exception:
    out = {"ts": ts, "kind": "raw", "raw": raw}
print(json.dumps(out))
' "$TS" 2>/dev/null)" || ROW=""

if [[ -n "$ROW" ]] && append_jsonl replies.jsonl "$ROW"; then
    exit 0
fi

# Last-ditch: python crashed entirely or the write failed. Emit the
# minimal row directly with bash so operator's tail at least sees
# activity and the turn ends with a degraded message instead of
# timing out. Even this can fail (ENOSPC, perms) — that's fine, we
# still exit 0 per the contract.
append_jsonl replies.jsonl "$(printf '{"ts": %s, "kind": "crashed"}' "$TS")"
exit 0
