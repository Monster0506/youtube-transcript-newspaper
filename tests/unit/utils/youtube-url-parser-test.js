import { module, test } from 'qunit';
import { parseYouTubeUrl } from 'youtube-transcript-viewer/utils/youtube-url-parser';

module('Unit | Utility | youtube-url-parser', function () {
  test('extracts video ID from youtube.com watch URL', function (assert) {
    const videoId = parseYouTubeUrl(
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ'
    );
    assert.strictEqual(videoId, 'dQw4w9WgXcQ');
  });

  test('extracts video ID from youtu.be URL', function (assert) {
    const videoId = parseYouTubeUrl('https://youtu.be/dQw4w9WgXcQ');
    assert.strictEqual(videoId, 'dQw4w9WgXcQ');
  });

  test('extracts video ID from youtube.com/v/ URL', function (assert) {
    const videoId = parseYouTubeUrl('https://www.youtube.com/v/dQw4w9WgXcQ');
    assert.strictEqual(videoId, 'dQw4w9WgXcQ');
  });

  test('extracts video ID from youtube.com/embed/ URL', function (assert) {
    const videoId = parseYouTubeUrl(
      'https://www.youtube.com/embed/dQw4w9WgXcQ'
    );
    assert.strictEqual(videoId, 'dQw4w9WgXcQ');
  });

  test('returns video ID if already just an ID', function (assert) {
    const videoId = parseYouTubeUrl('dQw4w9WgXcQ');
    assert.strictEqual(videoId, 'dQw4w9WgXcQ');
  });

  test('returns null for invalid URL', function (assert) {
    const videoId = parseYouTubeUrl('https://example.com');
    assert.strictEqual(videoId, null);
  });

  test('handles URLs with additional parameters', function (assert) {
    const videoId = parseYouTubeUrl(
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=123s'
    );
    assert.strictEqual(videoId, 'dQw4w9WgXcQ');
  });
});
