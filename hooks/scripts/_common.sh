#!/usr/bin/env bash
# Common gate + helpers for operator hook scripts.
#
# === The operator hook contract ===
#
# Every operator hook MUST follow these rules. They exist because
# Claude Code reads a hook's exit code as a control signal — exit 2
# means "block," any other non-zero means "non-blocking error, proceed
# anyway." For lifecycle hooks (Stop / SessionStart) a stray non-zero
# exit means the meeting silently hangs at operator's tail timeout.
# For decision hooks like PermissionRequest a stray non-zero means a
# tool call runs unapproved. Both are bad outcomes that cheap
# discipline avoids.
#
#   1. Always exit 0.
#   2. Express decisions as JSON on stdout when the event supports it.
#   3. On any internal error, fall back to a documented safe state
#      (write a degraded payload, write nothing, emit a JSON deny —
#      whichever is right for the event) and STILL exit 0.
#   4. Do not rely on `set -e` for control flow. Handle errors
#      explicitly so the safe-fallback path is always reachable.
#
# Sourcing this file deliberately does NOT opt you into `set -e`. It
# only sets `-uo pipefail` so unhandled command failures don't bypass
# your safe-fallback path.
#
# Every operator hook is gated on $OPERATOR_SESSION_DIR. This env var
# is exported by the operator CLI before it spawns its inner-claude
# subprocess, and inherited by every subprocess of that claude
# (including these hooks). The user's normal Claude Code sessions
# never have it set, so the hooks no-op cleanly there.
#
# Source from each hook script:
#   . "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

set -uo pipefail

# No-op outside an operator meeting.
if [[ -z "${OPERATOR_SESSION_DIR:-}" ]]; then
    exit 0
fi

# Best-effort: ensure the dir exists. Operator's CLI created it at
# provider construction time; this is a defense against a misbehaving
# test or a hand-set env var pointing at a missing dir. If we can't
# even create it, exit 0 silently — there is nowhere safe to write.
if ! mkdir -p "$OPERATOR_SESSION_DIR" 2>/dev/null; then
    exit 0
fi

ts_now() {
    python3 -c 'import time; print(f"{time.time():.3f}")' 2>/dev/null \
        || date +%s.000
}

# append_jsonl <filename> <json-body>
# Append a JSONL row to a file under $OPERATOR_SESSION_DIR. Returns 0
# on success, non-zero on write failure. Wrapped in a `{ ...; } 2>/dev/null`
# block (not just `cmd 2>/dev/null`) because bash processes redirects
# left-to-right — a trailing 2>/dev/null on the printf line happens
# AFTER the shell tries to open the file, so the "Permission denied"
# message has already escaped to the parent's stderr and Claude Code
# surfaces it as a spurious hook-error notice. The group form
# redirects stderr first, then the inner redirect's open-failure
# complaint goes to /dev/null. The script's own safe-fallback path
# is the right place to surface a real failure.
append_jsonl() {
    local file="$1" body="$2"
    { printf '%s\n' "$body" >> "$OPERATOR_SESSION_DIR/$file"; } 2>/dev/null
}

# safe_emit_permreq_deny <message>
# Print a PermissionRequest "deny" hookSpecificOutput JSON object to
# stdout. Used by the upcoming permission_request.sh hook for both
# the intentional-deny path and any internal-error fallback. Lives
# here so the JSON shape is in one place and reusable for any future
# decision-emitting hook. Has a hardcoded fallback string in case
# python3 itself isn't available — never let this helper fail.
safe_emit_permreq_deny() {
    local message="${1:-denied by operator}"
    python3 -c '
import json, sys
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "PermissionRequest",
    "decision": {"behavior": "deny", "message": sys.argv[1]}
}}))
' "$message" 2>/dev/null || \
        printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"deny","message":"denied (fallback)"}}}'
}
