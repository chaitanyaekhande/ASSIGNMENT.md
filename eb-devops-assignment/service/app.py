"""Tiny HTTP service. APP_NAME / VERSION come from the environment, but if a
ConfigMap volume is mounted at CONFIG_DIR the files there win. Kubelet refreshes
mounted ConfigMaps in place, so patching the ConfigMap changes GET / without a
pod restart (env vars cannot do that)."""
import json
import os
import socket
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

CONFIG_DIR = os.environ.get("CONFIG_DIR", "/etc/app-config")


def setting(key, default=""):
    try:
        with open(os.path.join(CONFIG_DIR, key), encoding="utf-8") as f:
            return f.read().strip()
    except OSError:
        return os.environ.get(key, default)


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, body, ctype="application/json"):
        data = body.encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        path = self.path.split("?", 1)[0]
        if path == "/":
            self._send(200, json.dumps({
                "app": setting("APP_NAME"),
                "version": setting("VERSION"),
                "pod": socket.gethostname(),
            }))
        elif path == "/healthz":
            self._send(200, "ok", "text/plain")
        else:
            self._send(404, json.dumps({"error": "not found"}))

    def log_message(self, fmt, *args):
        print("%s %s" % (self.address_string(), fmt % args), flush=True)


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    ThreadingHTTPServer(("0.0.0.0", port), Handler).serve_forever()
