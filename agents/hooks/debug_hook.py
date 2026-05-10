#!/usr/bin/env python3
"""One-shot debug hook — dumps stdin to /tmp/claude_hook_debug.log"""
import json, sys, os, time

log = "/tmp/claude_hook_debug.log"
try:
    raw = sys.stdin.read()
    payload = json.loads(raw) if raw.strip() else {}
except Exception as e:
    payload = {"_parse_error": str(e), "_raw": raw[:500] if raw else ""}

entry = {
    "ts": time.strftime("%Y-%m-%dT%H:%M:%S"),
    "env_tokens": {
        k: os.environ[k] for k in os.environ if "TOKEN" in k.upper() or "USAGE" in k.upper()
    },
    "payload": payload,
}

with open(log, "a") as f:
    f.write(json.dumps(entry, indent=2) + "\n---\n")
