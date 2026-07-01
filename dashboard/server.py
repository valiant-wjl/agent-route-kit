#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parents[1]
INDEX = ROOT / "dashboard" / "index.html"
HOST = "127.0.0.1"
PORT = int(os.environ.get("AGENT_ROUTE_KIT_DASHBOARD_PORT", "8765"))

COMMANDS = {
    "status": ["bash", str(ROOT / "tools/net"), "status"],
    "diagnose": ["bash", str(ROOT / "tools/diagnose")],
    "on": ["bash", str(ROOT / "tools/net"), "on"],
    "ai-only": ["bash", str(ROOT / "tools/net"), "ai-only"],
    "bypass": ["bash", str(ROOT / "tools/net"), "bypass"],
}


def run_command(action: str) -> dict[str, object]:
    completed = subprocess.run(
        COMMANDS[action],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=30,
        check=False,
    )
    return {
        "ok": completed.returncode == 0,
        "exit_code": completed.returncode,
        "output": completed.stdout[-8000:],
    }


class Handler(BaseHTTPRequestHandler):
    def log_message(self, format: str, *args: object) -> None:
        return

    def send_json(self, payload: dict[str, object], status: int = 200) -> None:
        data = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self) -> None:
        path = urlparse(self.path).path
        if path in {"/", "/index.html"}:
            data = INDEX.read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
            return
        self.send_error(404)

    def do_POST(self) -> None:
        path = urlparse(self.path).path
        if not path.startswith("/api/"):
            self.send_error(404)
            return
        action = path.removeprefix("/api/")
        if action not in COMMANDS:
            self.send_json({"ok": False, "error": "unknown action"}, status=404)
            return
        try:
            self.send_json(run_command(action))
        except subprocess.TimeoutExpired:
            self.send_json({"ok": False, "exit_code": 124, "error": "command timed out"}, status=504)


def main() -> None:
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"Dashboard listening on http://{HOST}:{PORT}")
    server.serve_forever()


if __name__ == "__main__":
    main()
