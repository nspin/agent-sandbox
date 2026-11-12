"""Transparent logging wrapper for the Claude Code VS Code extension.

Set as `claudeCode.claudeProcessWrapper`. The extension invokes it as

    claude-process-wrapper <claude-executable> <claude args...>

It runs the real executable with the same args, relays stdin/stdout/stderr
byte-for-byte, forwards signals, and exits with the child's status. Along the
way it records everything to a per-invocation log directory, so we can see
what the extension does across a window close/reopen cycle:

    $CLAUDE_WRAPPER_LOG_DIR (default ~/.local/state/claude-process-wrapper)/
      <timestamp>-<pid>/
        meta.json    argv, cwd, ppid, selected env, start/end, exit status
        events.log   one line per event: "<ts> <dir> <payload>"
                     dir: IN (extension->claude), OUT (claude->extension),
                     ERR (claude stderr), SIG, EOF, EXIT

Logging failures never affect the relay.
"""

import datetime
import json
import os
import signal
import subprocess
import sys
import threading
import time

ENV_KEYS_TO_LOG = [
    "CLAUDE_CODE_ENTRYPOINT",
    "CLAUDE_CONFIG_DIR",
    "CLAUDE_CODE_SSE_PORT",
    "VSCODE_PID",
    "VSCODE_IPC_HOOK_CLI",
    "PATH",
]


def now():
    return datetime.datetime.now().isoformat(timespec="milliseconds")


class Log:
    def __init__(self):
        self.lock = threading.Lock()
        self.events = None
        self.dir = None
        try:
            base = os.environ.get("CLAUDE_WRAPPER_LOG_DIR") or os.path.join(
                os.path.expanduser("~"), ".local", "state", "claude-process-wrapper"
            )
            stamp = datetime.datetime.now().strftime("%Y%m%dT%H%M%S.%f")
            self.dir = os.path.join(base, f"{stamp}-{os.getpid()}")
            os.makedirs(self.dir, mode=0o700, exist_ok=True)
            self.events = open(os.path.join(self.dir, "events.log"), "a", buffering=1)
        except Exception:
            self.events = None

    def event(self, direction, payload):
        if self.events is None:
            return
        try:
            if isinstance(payload, bytes):
                payload = payload.decode("utf-8", errors="backslashreplace")
            payload = payload.rstrip("\n")
            with self.lock:
                self.events.write(f"{now()} {direction} {payload}\n")
        except Exception:
            pass

    def meta(self, data):
        if self.dir is None:
            return
        try:
            path = os.path.join(self.dir, "meta.json")
            with open(path + ".tmp", "w") as f:
                json.dump(data, f, indent=2)
            os.replace(path + ".tmp", path)
        except Exception:
            pass


def pump(src_fd, dst_fd, log, direction, on_eof=None):
    """Copy src_fd to dst_fd unchanged; log complete lines."""
    pending = b""
    dst_ok = True
    while True:
        try:
            chunk = os.read(src_fd, 65536)
        except OSError:
            chunk = b""
        if not chunk:
            break
        if dst_ok:
            try:
                view = memoryview(chunk)
                while view:
                    n = os.write(dst_fd, view)
                    view = view[n:]
            except OSError as e:
                # Destination gone (e.g. the extension went away). Keep
                # draining and logging so we still see what claude emitted.
                dst_ok = False
                log.event("EOF", f"{direction} destination closed: {e}")
        pending += chunk
        *lines, pending = pending.split(b"\n")
        for line in lines:
            log.event(direction, line)
    if pending:
        log.event(direction, pending)
    log.event("EOF", direction)
    if on_eof:
        on_eof()


def main():
    log = Log()
    if len(sys.argv) < 2:
        sys.stderr.write("usage: claude-process-wrapper <claude-executable> [args...]\n")
        return 2

    cmd = sys.argv[1:]
    meta = {
        "start": now(),
        "pid": os.getpid(),
        "ppid": os.getppid(),
        "cwd": os.getcwd(),
        "argv": cmd,
        "env": {k: os.environ.get(k) for k in ENV_KEYS_TO_LOG if k in os.environ},
    }
    log.meta(meta)

    try:
        child = subprocess.Popen(
            cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except OSError as e:
        log.event("EXIT", f"spawn failed: {e}")
        meta.update(end=now(), spawn_error=str(e))
        log.meta(meta)
        sys.stderr.write(f"claude-process-wrapper: cannot run {cmd[0]}: {e}\n")
        return 127

    meta["child_pid"] = child.pid
    log.meta(meta)

    def forward(signum, _frame):
        log.event("SIG", signal.Signals(signum).name)
        try:
            child.send_signal(signum)
        except Exception:
            pass

    for s in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP, signal.SIGQUIT,
              signal.SIGUSR1, signal.SIGUSR2):
        signal.signal(s, forward)
    # A closed stdout must not kill the wrapper before the child is reaped.
    signal.signal(signal.SIGPIPE, signal.SIG_IGN)

    def close_child_stdin():
        try:
            child.stdin.close()
        except Exception:
            pass

    threads = [
        threading.Thread(
            target=pump,
            args=(sys.stdin.fileno(), child.stdin.fileno(), log, "IN", close_child_stdin),
            daemon=True,
        ),
        threading.Thread(
            target=pump,
            args=(child.stdout.fileno(), sys.stdout.fileno(), log, "OUT"),
        ),
        threading.Thread(
            target=pump,
            args=(child.stderr.fileno(), sys.stderr.fileno(), log, "ERR"),
        ),
    ]
    for t in threads:
        t.start()

    while True:
        try:
            status = child.wait()
            break
        except InterruptedError:
            continue
    for t in threads[1:]:
        t.join(timeout=5)

    log.event("EXIT", str(status))
    meta.update(end=now(), exit_status=status)
    log.meta(meta)

    if status < 0:
        # Mirror death-by-signal so the extension sees the same thing.
        sig = -status
        signal.signal(sig, signal.SIG_DFL)
        os.kill(os.getpid(), sig)
        time.sleep(1)
        return 128 + sig
    return status


if __name__ == "__main__":
    sys.exit(main())
