#!/usr/bin/env python3
"""Minimaler HTTPS-Server für den Lautstärke-Monitor."""
import http.server
import json
import os
import socket
import ssl
import subprocess
import sys

DIR = os.path.dirname(os.path.abspath(__file__))
DOC_ROOT = os.environ.get("DOC_ROOT", DIR)
HOST = os.environ.get("HOST", "0.0.0.0")
PORT = int(os.environ.get("PORT", "8443"))
INDEX_FILE = os.environ.get("INDEX_FILE", "noise_monitor.html")
CERT_FILE = os.environ.get("CERT_FILE", os.path.join(DIR, "cert.pem"))
KEY_FILE = os.environ.get("KEY_FILE", os.path.join(DIR, "key.pem"))
STOP_PASSWORD = os.environ.get("STOP_PASSWORD", "Descarados")

os.chdir(DOC_ROOT)


def resolve_advertised_host():
    advertised_host = os.environ.get("ADVERTISE_HOST", "").strip()
    if advertised_host:
        return advertised_host

    if os.name == "posix" and sys.platform == "darwin":
        try:
            result = subprocess.run(
                "ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null",
                shell=True,
                check=False,
                capture_output=True,
                text=True,
            )
            ip = result.stdout.strip()
            if ip:
                return ip
        except OSError:
            pass

    try:
        return socket.gethostbyname(socket.gethostname())
    except OSError:
        return "localhost"


class Handler(http.server.SimpleHTTPRequestHandler):
    def _send_json(self, status_code, payload):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path in {"/", ""}:
            self.path = f"/{INDEX_FILE}"
        return super().do_GET()

    def do_POST(self):
        if self.path != "/api/authorize-stop":
            self.send_error(404, "File not found")
            return

        content_length = int(self.headers.get("Content-Length", "0"))
        raw_body = self.rfile.read(content_length) if content_length > 0 else b""

        try:
            data = json.loads(raw_body.decode("utf-8")) if raw_body else {}
        except json.JSONDecodeError:
            self._send_json(400, {"ok": False, "error": "invalid_json"})
            return

        password = data.get("password", "")
        if password == STOP_PASSWORD:
            self._send_json(200, {"ok": True})
            return

        self._send_json(401, {"ok": False, "error": "invalid_password"})

    def log_message(self, format, *args):
        print(f"  {self.address_string()} - {format % args}")


def main():
    ctx = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
    ctx.minimum_version = ssl.TLSVersion.TLSv1_2
    ctx.load_cert_chain(CERT_FILE, KEY_FILE)

    server = http.server.ThreadingHTTPServer((HOST, PORT), Handler)
    server.socket = ctx.wrap_socket(server.socket, server_side=True)

    advertised_host = resolve_advertised_host()

    print(f"""
╔══════════════════════════════════════════════════╗
║  🎤 Lautstärke-Monitor – HTTPS Server           ║
╚══════════════════════════════════════════════════╝

  🌐 Netzwerk:      https://{advertised_host}:{PORT}
  💻 Lokal:         https://localhost:{PORT}

  ⚠️  Zertifikats-Warnung im Browser:
     → 'Erweitert' → 'Trotzdem fortfahren'

  Stoppen: Ctrl+C
""")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n✅ Server gestoppt.")
    finally:
        server.server_close()


if __name__ == "__main__":

    main()


