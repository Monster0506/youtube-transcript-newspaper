/**
 * Calculates words per minute (WPM) from transcript data
 * @param {Array} transcript - Array of transcript segments
 * @returns {Object} Object containing wpm, totalWords, and durationSeconds
 */
export function calculateWPM(transcript) {
  if (!transcript || transcript.length === 0) {
    return { wpm: 0, totalWords: 0, durationSeconds: 0 };
  }

  const totalWords = transcript.reduce((count, segment) => {
    const words = segment.text
      .trim()
      .split(/\s+/)
      .filter((word) => word.length > 0);
    return count + words.length;
  }, 0);

  const lastSegment = transcript[transcript.length - 1];
  const totalDurationMs = lastSegment.offset + (lastSegment.duration || 0);
  const durationSeconds = totalDurationMs / 1000;

  const wpm =
    durationSeconds > 0 ? Math.round((totalWords / durationSeconds) * 60) : 0;

  return {
    wpm,
    totalWords,
    durationSeconds: Math.round(durationSeconds),
  };
}
