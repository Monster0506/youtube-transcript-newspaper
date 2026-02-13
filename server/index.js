const express = require('express');
const cors = require('cors');
const { YoutubeTranscript } = require('youtube-transcript');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

/**
 * GET /api/transcript/:videoId
 * Fetches transcript for a YouTube video
 */
app.get('/api/transcript/:videoId', async (req, res) => {
  const { videoId } = req.params;

  try {
    // Fetch transcript
    const transcriptData = await YoutubeTranscript.fetchTranscript(videoId);

    // Fetch video info to get chapters (if available)
    // Note: youtube-transcript doesn't provide chapters directly
    // You might need to use YouTube Data API v3 for chapters

    res.json({
      transcript: transcriptData,
      chapters: [], // TODO: Implement chapter extraction
    });
  } catch (error) {
    console.error('Error fetching transcript:', error);
    res.status(500).json({
      error: 'Failed to fetch transcript',
      message: error.message,
    });
  }
});

/**
 * Health check endpoint
 */
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.listen(PORT, () => {
  console.log(`Transcript API server running on http://localhost:${PORT}`);
});
