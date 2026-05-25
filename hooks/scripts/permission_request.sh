#!/usr/bin/env bash
# PermissionRequest hook — bridges Claude Code's permission dialog
# into meeting chat in operator's "yolo off" mode.
#
# Flow:
#   1. Receive PermissionRequest payload (tool_name, tool_input) on stdin.
#   2. Allocate a request_id, append a request record to
#      $OPERATOR_SESSION_DIR/permreq_requests.jsonl. Operator's provider
#      tails this file on the same poll loop it uses for replies.jsonl;
#      ChatRunner picks the new request up, posts the question to chat,
#      and watches for a yes/no reply.
#   3. Poll $OPERATOR_SESSION_DIR/permreq_answers/<request_id>.json for
#      the answer ChatRunner writes back atomically.
#   4. Emit `{hookSpecificOutput: {hookEventName: "PermissionRequest",
#      decision: <answer>}}` on stdout.
#
# Per the operator hook contract (see _common.sh): always exit 0.
# Any internal failure — IO error, timeout waiting for a chat reply,
# python crash, anything — falls back to a JSON deny with a clear
# message, NEVER exit 2 or bare non-zero. A bare non-zero exit on
# PermissionRequest is "non-blocking error → tool runs unapproved",
# which is the worst possible default in yolo-off mode (T3 of the
# 14_24_permreq spike confirmed exit 2 also breaks: it deny-loops
# claude until the per-turn timeout).
#
# Note: in yolo-on mode (--dangerously-skip-permissions), Claude Code
# never fires PermissionRequest at all, so this hook is inert in the
# default operator flow. Safe to register unconditionally.

. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

INPUT="$(cat)"

# Round-trip ceiling. Generous for an attentive meeting participant
# but well below the hook's own command timeout (600s default), so
# we always emit a clean JSON deny rather than getting killed by
# Claude Code mid-poll. After this, the hook denies and tells claude
# to suggest the user re-mention @claude. Overridable via env so
# tests can run with a short timeout.
TIMEOUT_S="${OPERATOR_PERMREQ_TIMEOUT_S:-120}"

# Single python invocation handles request emit + poll + decision
# emit. Bash wraps this with the safe-fallback if python itself
# crashes. Atomic-write contract: ChatRunner writes the answer to
# <request_id>.json.tmp then renames, so this script never reads a
# half-written file.
DECISION="$(printf '%s' "$INPUT" | python3 -c '
import json, os, pathlib, sys, time, uuid

TIMEOUT_S = float(sys.argv[1])

session_dir = pathlib.Path(os.environ["OPERATOR_SESSION_DIR"])
requests_path = session_dir / "permreq_requests.jsonl"
answers_dir = session_dir / "permreq_answers"

def emit_deny(msg):
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PermissionRequest",
        "decision": {"behavior": "deny", "message": msg},
    }}))

try:
    answers_dir.mkdir(exist_ok=True)
except OSError:
    emit_deny("operator could not prepare answers dir — denied for safety")
    sys.exit(0)

try:
    payload = json.loads(sys.stdin.read())
    if not isinstance(payload, dict):
        raise ValueError("payload not an object")
except Exception:
    emit_deny("operator could not parse the permission request — denied for safety")
    sys.exit(0)

request_id = uuid.uuid4().hex
record = {
    "request_id": request_id,
    "ts": time.time(),
    "tool_name": payload.get("tool_name"),
    "tool_input": payload.get("tool_input"),
}
try:
    with requests_path.open("a") as f:
        f.write(json.dumps(record) + "\n")
except OSError:
    emit_deny("operator could not enqueue the permission request — denied for safety")
    sys.exit(0)

answer_path = answers_dir / (request_id + ".json")
deadline = time.monotonic() + TIMEOUT_S
while time.monotonic() < deadline:
    if answer_path.exists():
        try:
            answer = json.loads(answer_path.read_text())
            if not isinstance(answer, dict) or "behavior" not in answer:
                raise ValueError("answer missing behavior")
        except Exception:
            emit_deny("operator wrote an unparseable answer — denied for safety")
            sys.exit(0)
        # Pass the answer through verbatim as the hookSpecificOutput
        # decision. ChatRunner is responsible for producing a well-
        # formed object (allow/deny + optional message + optional
        # updatedPermissions); operator-side tests cover that shape.
        print(json.dumps({"hookSpecificOutput": {
            "hookEventName": "PermissionRequest",
            "decision": answer,
        }}))
        sys.exit(0)
    time.sleep(0.2)

emit_deny("no response from the meeting after %ds — denied. @claude again to retry." % int(TIMEOUT_S))
' "$TIMEOUT_S" 2>/dev/null)" || DECISION=""

if [[ -n "$DECISION" ]]; then
    printf '%s\n' "$DECISION"
    exit 0
fi

# Last-ditch: the python pipeline crashed entirely (bad interpreter,
# stdlib missing). safe_emit_permreq_deny in _common.sh has its own
# python-less fallback so we never leave claude without an answer.
safe_emit_permreq_deny "operator hook crashed — denied for safety"
exit 0
