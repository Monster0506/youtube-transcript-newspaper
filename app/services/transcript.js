import Service from '@ember/service';
import { tracked } from '@glimmer/tracking';

export default class TranscriptService extends Service {
  @tracked isLoading = false;
  @tracked error = null;

  /**
   * Fetches transcript for a YouTube video
   * Note: youtube-transcript package works in Node.js only
   * In production, this should call a backend API
   *
   * @param {string} videoId - YouTube video ID
   * @returns {Promise<Object>} Transcript data with chapters
   */
  async fetchTranscript(videoId) {
    this.isLoading = true;
    this.error = null;

    try {
      // In a real app, call your backend API here
      // const response = await fetch(`/api/transcript/${videoId}`);
      // return await response.json();

      // Mock implementation for development
      // You'll need to implement a backend API endpoint
      // eslint-disable-next-line warp-drive/no-external-request-patterns
      const response = await fetch(`/api/transcript/${videoId}`);

      if (!response.ok) {
        throw new Error('Failed to fetch transcript');
      }

      const data = await response.json();

      return {
        transcript: data.transcript || [],
        chapters: data.chapters || [],
      };
    } catch (error) {
      this.error = error.message;
      throw error;
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * Groups transcript segments by chapters
   * @param {Array} transcript - Array of transcript segments
   * @param {Array} chapters - Array of chapter markers
   * @returns {Array} Grouped transcript by chapters
   */
  groupByChapters(transcript, chapters) {
    if (!chapters || chapters.length === 0) {
      return [
        {
          title: 'Transcript',
          startTime: 0,
          segments: transcript,
        },
      ];
    }

    const grouped = [];

    for (let i = 0; i < chapters.length; i++) {
      const chapter = chapters[i];
      const nextChapter = chapters[i + 1];

      const segments = transcript.filter((segment) => {
        const segmentTime = segment.offset / 1000; // Convert to seconds
        const isAfterStart = segmentTime >= chapter.startTime;
        const isBeforeEnd = !nextChapter || segmentTime < nextChapter.startTime;
        return isAfterStart && isBeforeEnd;
      });

      grouped.push({
        title: chapter.title,
        startTime: chapter.startTime,
        segments,
      });
    }

    return grouped;
  }
}
