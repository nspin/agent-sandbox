# claude-process-wrapper

Experiment toward keeping VS Code Claude sessions alive after the window closes.

The Claude Code extension launches its `claude` process through
`claudeCode.claudeProcessWrapper` (set in `../vscode.nix`) as
`<wrapper> <claude-executable> <args...>`. This wrapper is currently
**logging only**: it relays stdio unchanged and records argv, env, every
stdin/stdout/stderr line, signals and exit status per invocation under
`~/.local/state/claude-process-wrapper/<timestamp>-<pid>/`
(override with `CLAUDE_WRAPPER_LOG_DIR`).

The logs contain full conversation content; treat them as sensitive.

Note: with any wrapper set, the extension changes some behaviour (e.g. it
defaults permissionMode to "default" when none is chosen and stops tracking
the spawned PID). Remove the setting to go back to normal.

Next step, if the logs show it's feasible: a broker that keeps `claude`
running after the extension disconnects and reattaches on `--resume`.
