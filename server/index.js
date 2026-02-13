const express = require('express');
const cors = require('cors');
const { spawn } = require('child_process');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

/**
 * Fetch transcript via Python youtube-transcript-api subprocess
 */
function fetchTranscript(videoId) {
  return new Promise((resolve, reject) => {
    const scriptPath = path.join(__dirname, 'transcript.py');
    const proc = spawn('python', [scriptPath, videoId]);

    let stdout = '';
    let stderr = '';

    proc.stdout.on('data', (data) => {
      stdout += data;
    });
    proc.stderr.on('data', (data) => {
      stderr += data;
    });

    proc.on('close', () => {
      try {
        const result = JSON.parse(stdout.trim());
        if (result.error) {
          reject(new Error(result.error));
        } else {
          resolve(result);
        }
      } catch {
        reject(
          new Error(`Failed to parse transcript response: ${stderr || stdout}`)
        );
      }
    });

    proc.on('error', (err) => {
      reject(new Error(`Failed to start Python: ${err.message}`));
    });
  });
}

/**
 * Parse chapters from a video description containing timestamp lines like:
 *   (0:00) Intro  or  0:00 Intro  or  (1:23:45) Chapter Title
 */
function parseChaptersFromDescription(description) {
  if (!description) return [];
  const lines = description.split('\n');
  const chapters = [];
  // Match optional parens around HH:MM:SS or MM:SS, then chapter title
  const re = /(?:\()?(\d{1,2}:\d{2}(?::\d{2})?)(?:\))?\s+(.+)/;
  for (const line of lines) {
    const m = line.match(re);
    if (!m) continue;
    const parts = m[1].split(':').map(Number);
    const startTime =
      parts.length === 3
        ? parts[0] * 3600 + parts[1] * 60 + parts[2]
        : parts[0] * 60 + parts[1];
    chapters.push({ title: m[2].trim(), startTime });
  }
  // Need at least 2 timestamps to be valid chapter markers
  return chapters.length >= 2 ? chapters : [];
}

/**
 * Fetch chapters from video description via youtubei.js
 */
async function fetchChapters(videoId) {
  try {
    const { Innertube } = await import('youtubei.js');
    const yt = await Innertube.create({ retrieve_player: false });
    const info = await yt.getBasicInfo(videoId);
    const description = info.basic_info?.short_description || '';
    return parseChaptersFromDescription(description);
  } catch {
    return [];
  }
}

/**
 * GET /api/transcript/:videoId
 */
app.get('/api/transcript/:videoId', async (req, res) => {
  const { videoId } = req.params;

  try {
    const [transcript, chapters] = await Promise.all([
      fetchTranscript(videoId),
      fetchChapters(videoId),
    ]);

    res.json({ transcript, chapters });
  } catch (error) {
    console.error('Error fetching transcript:', error.message);
    res.status(500).json({
      error: 'Failed to fetch transcript',
      message: error.message,
    });
  }
});

app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

app.listen(PORT, () => {
  console.log(`Transcript API server running on http://localhost:${PORT}`);
});
