#!/usr/bin/env bash
# Courtesy stub for desktop-app models that pattern-match a
# "skill directory has a run.sh entrypoint" convention and invoke
# `bash run.sh <url>` or `source run.sh <url>` instead of the literal
# `operator dial claude …` command. Both paths produce identical
# behavior — operator self-daemonizes, so no nohup/redirect/& wrapping
# is needed at this layer.
exec operator dial claude "$@"
