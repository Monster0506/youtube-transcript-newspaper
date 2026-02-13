#!/usr/bin/env python
import sys
import json
from youtube_transcript_api import YouTubeTranscriptApi
from youtube_transcript_api._errors import NoTranscriptFound, TranscriptsDisabled

def main():
    if len(sys.argv) < 2:
        print(json.dumps({'error': 'No video ID provided'}))
        sys.exit(1)

    video_id = sys.argv[1]
    lang = sys.argv[2] if len(sys.argv) > 2 else 'en'

    try:
        api = YouTubeTranscriptApi()
        transcript = api.fetch(video_id, languages=[lang, 'en'])
        snippets = list(transcript)
        result = [
            {
                'text': s.text,
                'offset': int(s.start * 1000),
                'duration': int(s.duration * 1000),
            }
            for s in snippets
        ]
        print(json.dumps(result))
    except (NoTranscriptFound, TranscriptsDisabled) as e:
        print(json.dumps({'error': str(e)}))
        sys.exit(1)
    except Exception as e:
        print(json.dumps({'error': f'Unexpected error: {str(e)}'}))
        sys.exit(1)

if __name__ == '__main__':
    main()
