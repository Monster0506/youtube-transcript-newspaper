import { pageTitle } from 'ember-page-title';
import { on } from '@ember/modifier';

function speakerLines(segments) {
  const text = segments.map((s) => s.text).join(' ');

  // Multi-speaker: split on >> markers
  if (text.includes('>>')) {
    return text
      .split(/(?=>>)/)
      .map((s) => s.trim())
      .filter(Boolean);
  }

  // Sentence-based splitting — works when punctuation is present
  const sentences = text.match(/[^.!?]+[.!?]+["']?/g) ?? [];
  if (sentences.length >= 3) {
    const CHUNK = 4;
    const paras = [];
    for (let i = 0; i < sentences.length; i += CHUNK) {
      paras.push(
        sentences
          .slice(i, i + CHUNK)
          .join(' ')
          .trim()
      );
    }
    return paras;
  }

  // Fallback for unpunctuated auto-captions: group by ~150 words
  const TARGET = 150;
  const paras = [];
  let current = [];
  let wordCount = 0;
  for (const seg of segments) {
    current.push(seg.text);
    wordCount += seg.text.trim().split(/\s+/).length;
    if (wordCount >= TARGET) {
      paras.push(current.join(' ').trim());
      current = [];
      wordCount = 0;
    }
  }
  if (current.length) paras.push(current.join(' ').trim());
  return paras;
}

function formatTime(seconds) {
  if (typeof seconds !== 'number') return '0:00';
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = Math.floor(seconds % 60);
  if (h > 0) {
    return `${h}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  }
  return `${m}:${String(s).padStart(2, '0')}`;
}

<template>
  {{pageTitle "YouTube Transcript Viewer"}}

  <div class="min-h-screen bg-gray-50">
    <div class="max-w-4xl mx-auto px-4 py-8">

      {{! Header }}
      <header class="mb-8">
        <h1 class="text-4xl font-bold text-gray-900 mb-2">
          YouTube Transcript Viewer
        </h1>
        <p class="text-gray-600">
          Extract and read YouTube video transcripts as articles
        </p>
      </header>

      {{! URL Input Form }}
      <form {{on "submit" @controller.loadTranscript}} class="mb-8">
        <div class="flex gap-2">
          <label for="video-url" class="sr-only">YouTube URL or video ID</label>
          <input
            id="video-url"
            type="text"
            value={{@controller.videoUrl}}
            {{on "input" @controller.updateVideoUrl}}
            placeholder="Enter YouTube URL or video ID (e.g. https://youtu.be/...)"
            class="flex-1 px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
            disabled={{@controller.transcript.isLoading}}
          />
          <button
            type="submit"
            class="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed font-medium transition-colors"
            disabled={{@controller.transcript.isLoading}}
          >
            {{#if @controller.transcript.isLoading}}
              Loading…
            {{else}}
              Get Transcript
            {{/if}}
          </button>
        </div>
      </form>

      {{! Error Message }}
      {{#if @controller.errorMessage}}
        <div class="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg">
          <p class="text-red-800">{{@controller.errorMessage}}</p>
        </div>
      {{/if}}

      {{! Loading Spinner }}
      {{#if @controller.transcript.isLoading}}
        <div class="flex items-center justify-center py-12">
          <div
            class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"
          ></div>
          <p class="ml-4 text-gray-600">Fetching transcript…</p>
        </div>
      {{/if}}

      {{! Results }}
      {{#if @controller.groupedTranscript}}

        {{! Stats Bar }}
        {{#if @controller.transcriptStats}}
          <div
            class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6"
          >
            <h2
              class="text-sm font-semibold text-gray-500 uppercase tracking-wide mb-4"
            >Transcript Statistics</h2>
            <div class="grid grid-cols-3 gap-4">
              <div>
                <div
                  class="text-3xl font-bold text-blue-600"
                >{{@controller.transcriptStats.wpm}}</div>
                <div class="text-sm text-gray-500">Words / min</div>
              </div>
              <div>
                <div
                  class="text-3xl font-bold text-indigo-600"
                >{{@controller.transcriptStats.totalWords}}</div>
                <div class="text-sm text-gray-500">Total words</div>
              </div>
              <div>
                <div class="text-3xl font-bold text-purple-600">{{formatTime
                    @controller.transcriptStats.durationSeconds
                  }}</div>
                <div class="text-sm text-gray-500">Duration</div>
              </div>
            </div>
          </div>
        {{/if}}

        {{! Table of Contents }}
        <nav
          class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6"
        >
          <h2 class="text-lg font-semibold text-gray-900 mb-3">Table of Contents</h2>
          <ul class="space-y-1">
            {{#each @controller.groupedTranscript as |chapter index|}}
              <li>
                <a
                  href="#chapter-{{index}}"
                  class="flex items-center gap-2 px-3 py-2 rounded hover:bg-gray-100 transition-colors text-gray-700"
                >
                  <span
                    class="text-xs text-gray-400 font-mono w-10 shrink-0"
                  >{{formatTime chapter.startTime}}</span>
                  <span>{{chapter.title}}</span>
                </a>
              </li>
            {{/each}}
          </ul>
        </nav>

        {{! Clear Button }}
        <div class="mb-4 flex justify-end">
          <button
            type="button"
            {{on "click" @controller.clearTranscript}}
            class="text-sm text-gray-500 hover:text-gray-900 transition-colors"
          >
            ← New search
          </button>
        </div>

        {{! Transcript Article }}
        <article
          class="bg-white rounded-lg shadow-sm border border-gray-200 p-8"
        >
          {{#each @controller.groupedTranscript as |chapter index|}}
            <section id="chapter-{{index}}" class="mb-10 last:mb-0 scroll-mt-4">
              <h2
                class="text-xl font-semibold text-gray-900 mb-4 pb-2 border-b border-gray-200 flex items-center gap-3"
              >
                {{chapter.title}}
                <span
                  class="text-sm font-normal text-gray-400 font-mono"
                >{{formatTime chapter.startTime}}</span>
              </h2>
              <div class="text-gray-700 leading-relaxed space-y-1">
                {{#each (speakerLines chapter.segments) as |line|}}
                  <p>{{line}}</p>
                {{/each}}
              </div>
            </section>
          {{/each}}
        </article>

      {{/if}}

    </div>
  </div>

  {{outlet}}
</template>
