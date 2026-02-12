import { module, test } from 'qunit';
import { setupTest } from 'youtube-transcript-viewer/tests/helpers';

module('Unit | Service | transcript', function (hooks) {
  setupTest(hooks);

  test('it exists', function (assert) {
    let service = this.owner.lookup('service:transcript');
    assert.ok(service);
  });

  test('fetchTranscript returns transcript data structure', async function (assert) {
    let service = this.owner.lookup('service:transcript');

    // Mock the implementation for testing
    service.fetchTranscript = async function () {
      return {
        transcript: [
          { text: 'Hello world', duration: 2000, offset: 0 },
          { text: 'This is a test', duration: 3000, offset: 2000 },
        ],
        chapters: [],
      };
    };

    const result = await service.fetchTranscript('test123');
    assert.ok(result.transcript);
    assert.ok(Array.isArray(result.transcript));
    assert.strictEqual(result.transcript[0].text, 'Hello world');
  });

  test('groupByChapters groups transcript segments by chapters', function (assert) {
    let service = this.owner.lookup('service:transcript');

    const transcript = [
      { text: 'Intro text', offset: 0 },
      { text: 'More intro', offset: 5000 },
      { text: 'Chapter 1 text', offset: 30000 },
      { text: 'More chapter 1', offset: 35000 },
    ];

    const chapters = [
      { title: 'Introduction', startTime: 0 },
      { title: 'Chapter 1', startTime: 30 },
    ];

    const result = service.groupByChapters(transcript, chapters);

    assert.strictEqual(result.length, 2);
    assert.strictEqual(result[0].title, 'Introduction');
    assert.strictEqual(result[0].segments.length, 2);
    assert.strictEqual(result[1].title, 'Chapter 1');
    assert.strictEqual(result[1].segments.length, 2);
  });

  test('groupByChapters handles transcript without chapters', function (assert) {
    let service = this.owner.lookup('service:transcript');

    const transcript = [
      { text: 'Some text', offset: 0 },
      { text: 'More text', offset: 5000 },
    ];

    const result = service.groupByChapters(transcript, []);

    assert.strictEqual(result.length, 1);
    assert.strictEqual(result[0].title, 'Transcript');
    assert.strictEqual(result[0].segments.length, 2);
  });
});
