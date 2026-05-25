#!/usr/bin/env bash
# SessionStart hook — writes ready.flag into the session dir so the
# operator provider knows inner-claude is past TUI init and safe to
# receive its first bracketed-paste turn. ready.flag is the precise
# readiness signal — without it the provider's _wait_for_ready can
# only wait out its hard ceiling and then guess.
#
# ready.flag carries a JSON payload (despite the .flag name — kept
# so the provider and an older/newer plugin stay cross-compatible).
# The payload merges the SessionStart hook input (session_id,
# transcript_path, cwd, source, model) with a `ts` stamp this script
# adds. That lets the provider record boot timing on every run — the
# self-recording forensic trail — and pick up the transcript path
# without waiting for turn 0's Stop payload.
#
# Failure handling per the operator hook contract (see _common.sh):
# always exit 0. If the python merge fails, fall back to writing an
# empty ready.flag — the provider treats existence as the readiness
# signal and the payload as best-effort enrichment. If even that
# fails, exit 0 silently and accept that operator will time out at
# its 180s ready.flag ceiling — a loud, recoverable failure.
. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

INPUT="$(cat)"
READY="$OPERATOR_SESSION_DIR/ready.flag"

# Try to write the enriched payload atomically (write to .tmp, then
# rename — so the provider never reads a half-written file).
if printf '%s' "$INPUT" | python3 -c '
import json, os, sys, time
try:
    payload = json.loads(sys.stdin.read())
    if not isinstance(payload, dict):
        payload = {}
except Exception:
    payload = {}
payload["ts"] = time.time()
out = os.environ["OPERATOR_SESSION_DIR"] + "/ready.flag"
tmp = out + ".tmp"
with open(tmp, "w") as f:
    json.dump(payload, f)
os.replace(tmp, out)
' 2>/dev/null; then
    exit 0
fi

# Enriched write failed — fall back to an empty ready.flag so the
# provider still gets the readiness signal (forensic detail lost).
# `{ ...; } 2>/dev/null` group form, not trailing `2>/dev/null`, so
# the shell's "Permission denied" complaint on a read-only session
# dir doesn't leak (see append_jsonl in _common.sh for why).
{ : > "$READY"; } 2>/dev/null
exit 0
