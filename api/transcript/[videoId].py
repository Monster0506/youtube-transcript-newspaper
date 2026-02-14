from http.server import BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import json
import re
import requests
import random
from youtube_transcript_api import YouTubeTranscriptApi
from youtube_transcript_api.proxies import GenericProxyConfig
from youtube_transcript_api._errors import NoTranscriptFound, TranscriptsDisabled


def get_free_proxies(count=100):
    """Fetch multiple free proxies to try."""
    try:
        url = "https://api.proxyscrape.com/v2/?request=getproxies&protocol=http&timeout=3000&country=all&ssl=all&anonymity=all"
        resp = requests.get(url, timeout=5)
        if resp.status_code == 200:
            proxies = [p.strip() for p in resp.text.splitlines() if p.strip()]
            if proxies:
                # Return multiple proxies to try
                random.shuffle(proxies)
                return proxies[:count]
    except Exception:
        pass
    return []


def get_video_details(video_id):
    """Fetch video title and description via YouTube InnerTube API."""
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
        details = resp.json().get("videoDetails", {})
        return {
            "title": details.get("title", ""),
            "description": details.get("shortDescription", ""),
        }
    except Exception:
        return {"title": "", "description": ""}


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


class handler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)
        params = parse_qs(parsed.query)
        video_id = params.get("videoId", [None])[0]

        if not video_id:
            self._json(400, {"error": "Missing videoId"})
            return

        # Try to fetch transcript with retry logic
        fetched = None
        last_error = None
        
        # First, try with multiple proxies
        proxies = get_free_proxies(count=3)
            
        for proxy in proxies:
            try:
                api = YouTubeTranscriptApi(
                    proxy_config=GenericProxyConfig(
                        http_url=f"http://{proxy}",
                        https_url=f"http://{proxy}"
                    )
                )
                fetched = api.fetch(video_id, languages=["en"])
                break  # Success, stop trying other proxies
            except Exception as e:
                last_error = e
                continue
        
        # If all proxies failed, try direct connection
        if not fetched:
            try:
                api = YouTubeTranscriptApi()
                fetched = api.fetch(video_id, languages=["en"])
            except (NoTranscriptFound, TranscriptsDisabled) as e:
                self._json(404, {"error": str(e)})
                return
            except Exception as e:
                self._json(500, {"error": str(e)})
                return

        try:
            transcript = [
                {
                    "text": s.text,
                    "offset": int(s.start * 1000),
                    "duration": int(s.duration * 1000),
                }
                for s in fetched
            ]
            details = get_video_details(video_id)
            chapters = parse_chapters(details["description"])
            self._json(200, {"transcript": transcript, "chapters": chapters, "title": details["title"]})

        except Exception as e:
            self._json(500, {"error": str(e)})

    def _json(self, status, body):
        payload = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def log_message(self, *args):
        pass  # suppress default request logging
