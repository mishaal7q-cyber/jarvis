"""Start JARVIS.

    .venv\\Scripts\\python.exe run.py

The server binds to loopback only. Set JARVIS_PORT to change the port.
"""

from __future__ import annotations

import os
import socket
import sys
import threading
import time
import webbrowser
from pathlib import Path

APP_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(APP_DIR))

import uvicorn  # noqa: E402

from server.config import config  # noqa: E402


def _port_available(port: int) -> bool:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            sock.bind(("127.0.0.1", port))
        except OSError:
            return False
    return True


def _pick_port(preferred: int) -> int:
    if _port_available(preferred):
        return preferred
    for candidate in range(preferred + 1, preferred + 20):
        if _port_available(candidate):
            return candidate
    raise SystemExit("No free port found between %d and %d." % (preferred, preferred + 20))


def _open_when_ready(url: str) -> None:
    import urllib.request

    for _ in range(60):
        try:
            with urllib.request.urlopen(url + "/api/health", timeout=1) as response:
                if response.status == 200:
                    webbrowser.open(url)
                    return
        except Exception:
            time.sleep(0.4)


def main() -> None:
    preferred = int(os.environ.get("JARVIS_PORT", "8000"))
    port = _pick_port(preferred)
    url = f"http://127.0.0.1:{port}"

    llm = config.resolve_llm()
    name = config.get("assistant_name") or "JARVIS"

    print()
    print("  " + "=" * 58)
    print(f"   {name}  ·  local assistant")
    print("  " + "=" * 58)
    print(f"   Interface : {url}")
    print(f"   AI model  : {llm['provider_label']} / {llm['model'] or 'not set'}")
    print(f"   Status    : {'ready' if llm['configured'] else 'NO API KEY - offline commands only'}")
    print("   Stop with : Ctrl+C")
    print("  " + "=" * 58)
    print()

    if "--no-browser" not in sys.argv:
        threading.Thread(target=_open_when_ready, args=(url,), daemon=True).start()

    try:
        uvicorn.run(
            "server.app:app",
            host="127.0.0.1",
            port=port,
            log_level="warning",
            access_log=False,
        )
    except KeyboardInterrupt:
        print("\n  Shutting down.")


if __name__ == "__main__":
    main()
