import { pageTitle } from 'ember-page-title';
import { on } from '@ember/modifier';
import PhList from 'ember-phosphor-icons/components/ph-list';
import PhSidebar from 'ember-phosphor-icons/components/ph-sidebar';
import PhArrowLeft from 'ember-phosphor-icons/components/ph-arrow-left';

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

const currentYear = new Date().getFullYear();

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

  <div class="min-h-screen bg-newsprint">
    <div class="max-w-6xl mx-auto px-4 py-8">

      {{! Masthead }}
      <header class="mb-8 border-t-4 border-ink pt-3">
        <h1
          class="text-5xl font-bold text-ink font-serif text-center tracking-tight mb-3"
        >
          YouTube Transcript Viewer
        </h1>
        <div
          class="border-t-2 border-b border-ink py-1.5 flex items-center justify-between"
        >
          <p class="text-ink-secondary font-serif italic text-sm">
            Extract and read YouTube video transcripts as articles
          </p>
          <p
            class="text-ink-tertiary text-xs font-sans uppercase tracking-widest"
          >
            Est.
            {{currentYear}}
          </p>
        </div>
      </header>

      {{! URL Input Form — hidden when viewing a transcript }}
      {{#unless @controller.groupedTranscript}}
        <form {{on "submit" @controller.loadTranscript}} class="mb-8">
          <div class="flex gap-2">
            <label for="video-url" class="sr-only">YouTube URL or video ID</label>
            <input
              id="video-url"
              type="text"
              value={{@controller.videoUrl}}
              {{on "input" @controller.updateVideoUrl}}
              placeholder="Enter YouTube URL or video ID (e.g. https://youtu.be/...)"
              class="flex-1 px-4 py-3 border border-rule-dark bg-column text-ink placeholder:text-ink-tertiary focus:ring-2 focus:ring-ink focus:border-transparent outline-none font-serif"
              disabled={{@controller.transcript.isLoading}}
            />
            <button
              type="submit"
              class="px-6 py-3 bg-ink text-column hover:bg-ink/80 disabled:bg-ink-tertiary disabled:cursor-not-allowed font-sans font-medium tracking-wide transition-colors"
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
      {{/unless}}

      {{! Error Message }}
      {{#if @controller.errorMessage}}
        <div class="mb-6 p-4 bg-accent-bg border border-accent/30">
          <p class="text-accent font-serif">{{@controller.errorMessage}}</p>
        </div>
      {{/if}}

      {{! Loading Spinner }}
      {{#if @controller.transcript.isLoading}}
        <div class="flex items-center justify-center py-12">
          <div
            class="animate-spin rounded-full h-12 w-12 border-b-2 border-ink"
          ></div>
          <p class="ml-4 text-ink-secondary font-serif italic">
            Fetching transcript…
          </p>
        </div>
      {{/if}}

      {{! Results }}
      {{#if @controller.groupedTranscript}}

        {{! Sidebar + Article layout }}
        <div class="flex gap-4 items-start">

          {{! TOC Sidebar }}
          <aside class="shrink-0 sticky top-6 self-start">
            <button
              type="button"
              {{on "click" @controller.toggleToc}}
              class="flex items-center gap-2 px-3 py-2 bg-column border border-rule-dark hover:bg-newsprint transition-colors text-sm font-sans font-medium text-ink w-full"
            >
              {{#if @controller.tocOpen}}
                <PhSidebar @size="16" /><span>Hide chapters</span>
              {{else}}
                <PhList @size="16" /><span>Chapters</span>
              {{/if}}
            </button>

            {{#if @controller.tocOpen}}
              <nav
                class="mt-1 w-56 bg-column border border-t-0 border-rule-dark overflow-y-auto max-h-[calc(100vh-8rem)]"
              >
                <ul>
                  {{#each @controller.groupedTranscript as |chapter index|}}
                    <li class="border-b border-rule last:border-b-0">
                      <a
                        href="#chapter-{{index}}"
                        class="flex items-start gap-2 px-3 py-2 hover:bg-newsprint transition-colors text-ink text-sm"
                      >
                        <span
                          class="text-xs text-ink-tertiary font-mono mt-0.5 w-10 shrink-0"
                        >{{formatTime chapter.startTime}}</span>
                        <span
                          class="leading-tight font-serif"
                        >{{chapter.title}}</span>
                      </a>
                    </li>
                  {{/each}}
                </ul>
              </nav>
            {{/if}}
          </aside>

          {{! Main content }}
          <div class="flex-1 min-w-0">

            {{! Title + Clear Button }}
            <div class="mb-4 flex items-baseline justify-between gap-4">
              {{#if @controller.videoTitle}}
                <h2 class="text-2xl font-bold text-ink font-serif leading-tight truncate min-w-0">{{@controller.videoTitle}}</h2>
              {{/if}}
              <button
                type="button"
                {{on "click" @controller.clearTranscript}}
                class="text-sm text-ink-tertiary hover:text-ink transition-colors font-sans shrink-0 whitespace-nowrap"
              >
                <PhArrowLeft @size="16" class="inline" />
                New search
              </button>
            </div>

            {{! Transcript Article }}
            <article class="bg-column border border-rule-dark p-8">
              {{#each @controller.groupedTranscript as |chapter index|}}
                <section
                  id="chapter-{{index}}"
                  class="mb-10 last:mb-0 scroll-mt-4"
                >
                  <h2
                    class="text-xl font-bold text-ink font-serif mb-1 flex items-baseline gap-3"
                  >
                    {{chapter.title}}
                    <span
                      class="text-sm font-normal text-ink-tertiary font-mono"
                    >{{formatTime chapter.startTime}}</span>
                  </h2>
                  <div class="border-t-2 border-b border-ink mb-4"></div>
                  <div
                    class="text-ink-secondary font-serif leading-relaxed space-y-4 text-[1.0625rem]"
                  >
                    {{#each (speakerLines chapter.segments) as |line|}}
                      <p>{{line}}</p>
                    {{/each}}
                  </div>
                </section>
              {{/each}}
            </article>

            {{! Stats Bar — shown after the article }}
            {{#if @controller.transcriptStats}}
              <div class="bg-column border border-rule-dark p-6 mt-6">
                <h2
                  class="text-xs font-sans font-bold text-ink-tertiary uppercase tracking-widest mb-4 border-b border-rule pb-2"
                >Transcript Statistics</h2>
                <div class="grid grid-cols-3 gap-4 divide-x divide-rule">
                  <div class="text-center">
                    <div
                      class="text-4xl font-bold text-ink font-serif"
                    >{{@controller.transcriptStats.wpm}}</div>
                    <div
                      class="text-xs text-ink-tertiary font-sans uppercase tracking-wider mt-1"
                    >Words / min</div>
                  </div>
                  <div class="text-center">
                    <div
                      class="text-4xl font-bold text-ink font-serif"
                    >{{@controller.transcriptStats.totalWords}}</div>
                    <div
                      class="text-xs text-ink-tertiary font-sans uppercase tracking-wider mt-1"
                    >Total words</div>
                  </div>
                  <div class="text-center">
                    <div class="text-4xl font-bold text-ink font-serif">{{formatTime
                        @controller.transcriptStats.durationSeconds
                      }}</div>
                    <div
                      class="text-xs text-ink-tertiary font-sans uppercase tracking-wider mt-1"
                    >Duration</div>
                  </div>
                </div>
              </div>
            {{/if}}

          </div>
        </div>

      {{/if}}

    </div>
  </div>

  {{outlet}}
</template>
