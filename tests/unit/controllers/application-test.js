import { module, test } from 'qunit';
import { setupTest } from 'youtube-transcript-viewer/tests/helpers';

module('Unit | Controller | application', function (hooks) {
  setupTest(hooks);

  test('it exists', function (assert) {
    let controller = this.owner.lookup('controller:application');
    assert.ok(controller);
  });

  test('initial state is empty', function (assert) {
    let controller = this.owner.lookup('controller:application');
    assert.strictEqual(controller.v, null);
    assert.strictEqual(controller.videoUrl, '');
    assert.strictEqual(controller.groupedTranscript, null);
    assert.strictEqual(controller.transcriptStats, null);
    assert.strictEqual(controller.errorMessage, null);
  });

  test('updateVideoUrl updates videoUrl and clears error', function (assert) {
    let controller = this.owner.lookup('controller:application');
    controller.errorMessage = 'some error';

    controller.updateVideoUrl({
      target: { value: 'https://youtu.be/dQw4w9WgXcQ' },
    });

    assert.strictEqual(controller.videoUrl, 'https://youtu.be/dQw4w9WgXcQ');
    assert.strictEqual(controller.errorMessage, null);
  });

  test('loadTranscript sets errorMessage for invalid URL', async function (assert) {
    let controller = this.owner.lookup('controller:application');
    controller.videoUrl = 'not-a-valid-url';

    await controller.loadTranscript({ preventDefault() {} });

    assert.strictEqual(
      controller.errorMessage,
      'Invalid YouTube URL or video ID'
    );
    assert.strictEqual(controller.groupedTranscript, null);
  });

  test('clearTranscript resets all state', function (assert) {
    let controller = this.owner.lookup('controller:application');
    controller.videoUrl = 'https://youtu.be/dQw4w9WgXcQ';
    controller.groupedTranscript = [{ title: 'Intro', segments: [] }];
    controller.transcriptStats = {
      wpm: 120,
      totalWords: 500,
      durationSeconds: 250,
    };
    controller.errorMessage = 'some error';

    controller.clearTranscript();

    assert.strictEqual(controller.v, null);
    assert.strictEqual(controller.videoUrl, '');
    assert.strictEqual(controller.groupedTranscript, null);
    assert.strictEqual(controller.transcriptStats, null);
    assert.strictEqual(controller.errorMessage, null);
  });
});
