#!/usr/bin/env python
"""Local development API server - mirrors api/transcript/[videoId].py for Vercel."""
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import json
import os
import re
import requests
import random
from youtube_transcript_api import YouTubeTranscriptApi
from youtube_transcript_api.proxies import GenericProxyConfig
from youtube_transcript_api._errors import NoTranscriptFound, TranscriptsDisabled

# Webapp directory for serving static files
WEBAPP_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "webapp")
PORT = 3001

CONTENT_TYPES = {
    ".html": "text/html",
    ".css": "text/css",
    ".js": "application/javascript",
    ".json": "application/json",
    ".png": "image/png",
    ".jpg": "image/jpeg",
    ".svg": "image/svg+xml",
    ".ico": "image/x-icon",
    ".woff2": "font/woff2",
    ".woff": "font/woff",
}


def get_free_proxies(count=5):
    """Fetch multiple free proxies to try."""
    try:
        url = "https://api.proxyscrape.com/v2/?request=getproxies&protocol=http&timeout=3000&country=all&ssl=all&anonymity=all"
        resp = requests.get(url, timeout=5)
        if resp.status_code == 200:
            proxies = [p.strip() for p in resp.text.splitlines() if p.strip()]
            if proxies:
                random.shuffle(proxies)
                return proxies[:count]
    except Exception as e:
        print(f"[api] Failed to fetch proxies: {e}")
    return []


def get_description(video_id):
    """Fetch video description via YouTube InnerTube API."""
    try:
        resp = requests.post(
            "https://www.youtube.com/youtubei/v1/player",
            json={
                "videoId": video_id,
                "context": {
                    "client": {
                        "clientName": "ANDROID",
                        "clientVersion": "19.09.37",
                        "androidSdkVersion": 30,
                    }
                },
            },
            headers={"Content-Type": "application/json"},
            timeout=10,
        )
        return resp.json().get("videoDetails", {}).get("shortDescription", "")
    except Exception:
        return ""


def parse_chapters(description):
    """Parse chapter timestamps from video description."""
    if not description:
        return []
    pattern = re.compile(r"(?:\()?(\d{1,2}:\d{2}(?::\d{2})?)(?:\))?\s+(.+)")
    chapters = []
    for line in description.split("\n"):
        m = pattern.match(line.strip())
        if not m:
            continue
        parts = list(map(int, m.group(1).split(":")))
        start_time = (
            parts[0] * 3600 + parts[1] * 60 + parts[2]
            if len(parts) == 3
            else parts[0] * 60 + parts[1]
        )
        chapters.append({"title": m.group(2).strip(), "startTime": start_time})
    return chapters if len(chapters) >= 2 else []


def fetch_transcript(video_id):
    """Try direct connection first, then fall back to proxies."""
    # Attempt 1: direct (fastest, works when not rate-limited)
    try:
        print("[api] Trying direct connection...")
        api = YouTubeTranscriptApi()
        result = api.fetch(video_id, languages=["en"])
        print("[api] [OK] Direct connection succeeded")
        return result
    except (NoTranscriptFound, TranscriptsDisabled):
        raise  # These are real errors, don't retry with proxies
    except Exception as e:
        print(f"[api] [FAIL] Direct connection failed: {type(e).__name__}: {e}")

    # Attempt 2: try proxies
    proxies = get_free_proxies(count=100)
    if proxies:
        print(f"[api] Trying {len(proxies)} proxies...")

    for proxy in proxies:
        try:
            print(f"[api] Trying proxy: {proxy}")
            api = YouTubeTranscriptApi(
                proxy_config=GenericProxyConfig(
                    http_url=f"http://{proxy}",
                    https_url=f"http://{proxy}",
                )
            )
            result = api.fetch(video_id, languages=["en"])
            print(f"[api] [OK] Proxy {proxy} succeeded")
            return result
        except Exception as e:
            print(f"[api] [FAIL] Proxy {proxy}: {type(e).__name__}")
            continue

    raise RuntimeError(
        "Could not fetch transcript. YouTube may be rate-limiting this IP. "
        "Please try again in a few minutes."
    )


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path

        # --- API routes ---
        if path == "/health":
            self._json(200, {"status": "ok"})
            return

        m = re.match(r"^/api/transcript/([^/?]+)", path)
        if m:
            self._handle_transcript(m.group(1))
            return

        # --- Static file serving (webapp/) ---
        self._serve_static(path)

    def _handle_transcript(self, video_id):
        try:
            fetched = fetch_transcript(video_id)
            transcript = [
                {
                    "text": s.text,
                    "offset": int(s.start * 1000),
                    "duration": int(s.duration * 1000),
                }
                for s in fetched
            ]
            chapters = parse_chapters(get_description(video_id))
            self._json(200, {"transcript": transcript, "chapters": chapters})

        except (NoTranscriptFound, TranscriptsDisabled) as e:
            self._json(404, {"error": str(e)})
        except Exception as e:
            self._json(500, {"error": str(e)})

    def _serve_static(self, path):
        """Serve static files from the webapp/ directory."""
        if path == "/" or path == "":
            path = "/index.html"

        # Sanitize path to prevent directory traversal
        safe_path = os.path.normpath(path.lstrip("/"))
        file_path = os.path.join(WEBAPP_DIR, safe_path)
        file_path = os.path.normpath(file_path)

        # Security: make sure we're still inside WEBAPP_DIR
        if not file_path.startswith(os.path.normpath(WEBAPP_DIR)):
            self._json(403, {"error": "Forbidden"})
            return

        if not os.path.isfile(file_path):
            self._json(404, {"error": "Not found"})
            return

        ext = os.path.splitext(file_path)[1].lower()
        content_type = CONTENT_TYPES.get(ext, "application/octet-stream")

        try:
            with open(file_path, "rb") as f:
                data = f.read()
            self.send_response(200)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-cache")
            self.end_headers()
            self.wfile.write(data)
        except Exception:
            self._json(500, {"error": "Failed to read file"})

    def _json(self, status, body):
        payload = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, fmt, *args):
        print(f"[api] {args[0]}")


if __name__ == "__main__":
    print(f"Serving webapp from: {WEBAPP_DIR}")
    server = HTTPServer(("127.0.0.1", PORT), Handler)
    print(f"Running on http://127.0.0.1:{PORT}")
    server.serve_forever()
