/**
 * Parses a YouTube URL or video ID and returns the video ID
 * @param {string} input - YouTube URL or video ID
 * @returns {string|null} - Video ID or null if invalid
 */
export function parseYouTubeUrl(input) {
  if (!input) {
    return null;
  }

  // If it's already just an ID (11 characters, alphanumeric + - and _)
  const idPattern = /^[a-zA-Z0-9_-]{11}$/;
  if (idPattern.test(input)) {
    return input;
  }

  try {
    const url = new URL(input);

    // youtube.com/watch?v=VIDEO_ID
    if (url.hostname.includes('youtube.com') && url.searchParams.has('v')) {
      return url.searchParams.get('v');
    }

    // youtu.be/VIDEO_ID
    if (url.hostname === 'youtu.be') {
      return url.pathname.slice(1).split('?')[0];
    }

    // youtube.com/v/VIDEO_ID or youtube.com/embed/VIDEO_ID
    if (url.hostname.includes('youtube.com')) {
      const match = url.pathname.match(/\/(v|embed)\/([a-zA-Z0-9_-]{11})/);
      if (match) {
        return match[2];
      }
    }
  } catch {
    return null;
  }

  return null;
}
