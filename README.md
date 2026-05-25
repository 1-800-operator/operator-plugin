# operator-plugin

The Claude Code plugin for [operator](https://1-800-operator.com) — Claude Code in your Google Meet.

This plugin adds four slash commands to Claude Code:

- `/operator:dial <meet-url>` — send Claude into the Meet
- `/operator:status` — check whether operator is in a meeting
- `/operator:hangup` — disconnect the bot (the human stays in the call)
- `/operator:doctor` — run the install/auth/permissions diagnostic

The plugin is a thin shim. The CLI it shells out to (`operator`) does the work — dial Chrome, the chat-message MutationObserver, the audio helper, the inner-claude subprocess, the whole pipeline.

## Install

1. Install the operator CLI:

   ```bash
   curl -fsSL https://1-800-operator.com/install.sh | bash
   ```

2. Add this plugin to Claude Code:

   ```bash
   /plugin install 1-800-operator/operator-plugin
   ```

After both, run `/operator:doctor` to confirm everything's wired.

## How it ties together

When you invoke `/operator:dial <meet-url>`, the plugin substitutes your current Claude Code session ID into the spawn command:

```bash
nohup operator dial claude --resume-session ${CLAUDE_SESSION_ID} <meet-url> &
```

Operator launches a dedicated Chrome window, joins the Meet, and bridges the *same* session into the meeting. When someone @mentions Claude in chat, it answers in your live Claude Code session — context flows both ways.

## Source

- CLI: [github.com/1-800-operator/operator](https://github.com/1-800-operator/operator)
- Plugin: [github.com/1-800-operator/operator-plugin](https://github.com/1-800-operator/operator-plugin)
- License: MIT
