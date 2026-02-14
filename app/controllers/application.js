import Controller from '@ember/controller';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { parseYouTubeUrl } from 'youtube-transcript-viewer/utils/youtube-url-parser';
import { calculateWPM } from 'youtube-transcript-viewer/utils/calculate-wpm';

export default class ApplicationController extends Controller {
  @service transcript;

  queryParams = ['v'];

  @tracked v = null;
  @tracked videoUrl = '';
  @tracked videoTitle = '';
  @tracked groupedTranscript = null;
  @tracked transcriptStats = null;
  @tracked errorMessage = null;
  @tracked tocOpen = false;
  @tracked darkMode = false;

  constructor() {
    super(...arguments);
    // Restore theme from localStorage
    const saved = localStorage.getItem('theme');
    if (
      saved === 'dark' ||
      (!saved && window.matchMedia('(prefers-color-scheme: dark)').matches)
    ) {
      this.darkMode = true;
      document.documentElement.classList.add('dark');
    }
  }

  @action
  toggleToc() {
    this.tocOpen = !this.tocOpen;
  }

  @action
  toggleDarkMode() {
    this.darkMode = !this.darkMode;
    document.documentElement.classList.toggle('dark', this.darkMode);
    localStorage.setItem('theme', this.darkMode ? 'dark' : 'light');
  }

  @action
  updateVideoUrl(event) {
    this.videoUrl = event.target.value;
    this.errorMessage = null;
  }

  @action
  async autoLoad() {
    await this.loadTranscript({ preventDefault() {} });
  }

  @action
  async loadTranscript(event) {
    event.preventDefault();

    this.errorMessage = null;
    this.groupedTranscript = null;
    this.transcriptStats = null;
    this.videoTitle = '';

    const videoId = parseYouTubeUrl(this.videoUrl);

    if (!videoId) {
      this.errorMessage = 'Invalid YouTube URL or video ID';
      return;
    }

    try {
      const data = await this.transcript.fetchTranscript(videoId);

      this.groupedTranscript = this.transcript.groupByChapters(
        data.transcript,
        data.chapters
      );

      this.transcriptStats = calculateWPM(data.transcript);
      this.videoTitle = data.title || '';
      this.v = videoId;
    } catch (error) {
      this.errorMessage = error.message || 'Failed to load transcript';
    }
  }

  @action
  clearTranscript() {
    this.v = null;
    this.videoUrl = '';
    this.videoTitle = '';
    this.groupedTranscript = null;
    this.transcriptStats = null;
    this.errorMessage = null;
    this.tocOpen = false;
  }
}
