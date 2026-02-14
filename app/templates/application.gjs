import { pageTitle } from 'ember-page-title';
import { on } from '@ember/modifier';
import PhList from 'ember-phosphor-icons/components/ph-list';
import PhSidebar from 'ember-phosphor-icons/components/ph-sidebar';
import PhArrowLeft from 'ember-phosphor-icons/components/ph-arrow-left';
import PhMoon from 'ember-phosphor-icons/components/ph-moon';
import PhSun from 'ember-phosphor-icons/components/ph-sun';

function speakerLines(segments) {
  const fullText = segments.map((s) => s.text).join(' ');
  const TARGET = 150;

  // 1. Split on speaker markers (>>) — each block is one speaker's turn
  const speakerBlocks = fullText
    .split(/(?=>>)/)
    .map((s) => s.trim())
    .filter(Boolean);

  const paragraphs = [];

  for (const block of speakerBlocks) {
    // 2. Try to split each speaker block into sentences
    const sentences = block.match(/[^.!?]+[.!?]+["']?/g);

    if (sentences && sentences.length > 0) {
      // Sentence-aware splitting: break at the sentence boundary closest to TARGET words
      let current = [];
      let wordCount = 0;

      for (const sentence of sentences) {
        const trimmed = sentence.trim();
        const sentenceWords = trimmed.split(/\s+/).length;

        current.push(trimmed);
        wordCount += sentenceWords;

        if (wordCount >= TARGET && current.length > 0) {
          // Check: is it closer to TARGET with or without this sentence?
          const withThis = wordCount;
          const withoutThis = wordCount - sentenceWords;

          if (
            current.length > 1 &&
            Math.abs(withoutThis - TARGET) < Math.abs(withThis - TARGET)
          ) {
            // Closer without — break before this sentence
            current.pop();
            paragraphs.push(current.join(' '));
            current = [trimmed];
            wordCount = sentenceWords;
          } else {
            // Closer with — break after this sentence
            paragraphs.push(current.join(' '));
            current = [];
            wordCount = 0;
          }
        }
      }

      if (current.length) {
        paragraphs.push(current.join(' '));
      }
    } else {
      // 3. No punctuation — fall back to raw word-count grouping
      const words = block.split(/\s+/).filter(Boolean);
      for (let i = 0; i < words.length; i += TARGET) {
        paragraphs.push(words.slice(i, i + TARGET).join(' '));
      }
    }
  }

  return paragraphs.length > 0 ? paragraphs : [fullText];
}

const currentYear = new Date().getFullYear();
const edition = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'][
  Math.floor(Math.random() * 10)
];
const number = Math.floor(Math.random() * 100);
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

function todayDate() {
  return new Date().toLocaleDateString('en-US', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
}

function isFirstChapter(index) {
  return index === 0;
}

<template>
  {{pageTitle "YouTube Transcript Viewer"}}

  <div class="min-h-screen bg-newsprint paper-texture">
    <div class="max-w-5xl mx-auto px-4 py-8">

      {{! ═══ Masthead ═══ }}
      <header class="mb-8">
        {{! Top decorative rule }}
        <div class="border-t-[6px] border border-ink mb-1"></div>

        {{! Dateline bar }}
        <div class="flex items-center justify-between mb-3">
          <span class="dateline">{{todayDate}}</span>
          <button
            type="button"
            {{on "click" @controller.toggleDarkMode}}
            class="theme-toggle"
          >
            {{#if @controller.darkMode}}
              <PhSun @size="14" />
              <span>Morning Edition</span>
            {{else}}
              <PhMoon @size="14" />
              <span>Evening Edition</span>
            {{/if}}
          </button>
          <span class="dateline">Vol. {{edition}} No. {{number}}</span>
        </div>

        {{! Newspaper title }}
        <div class="border-t-1 border-ink pt-2 pb-1">
          <h1
            class="text-6xl font-headline font-black text-ink text-center tracking-tight leading-none"
          >The Transcript Viewer</h1>
        </div>

        {{! Subtitle bar }}
        <div class="border-t-[6px] border border-ink mt-1"></div>
      </header>

      {{! ═══ URL Input Form — hidden when viewing a transcript ═══ }}
      {{#unless @controller.groupedTranscript}}
        <div class="mt-12 mb-12 max-w-2xl mx-auto">

          <p
            class="text-center text-ink-secondary font-serif italic text-lg mb-8"
          >
            Paste a YouTube URL below to extract and read its transcript
          </p>

          <form {{on "submit" @controller.loadTranscript}}>
            <div class="flex gap-2">
              <label for="video-url" class="sr-only">YouTube URL or video ID</label>
              <input
                id="video-url"
                type="text"
                value={{@controller.videoUrl}}
                {{on "input" @controller.updateVideoUrl}}
                placeholder="https://youtu.be/... or video ID"
                class="flex-1 px-4 py-3 border border-rule-dark bg-column text-ink placeholder:text-ink-tertiary focus:ring-2 focus:ring-accent focus:border-transparent outline-none font-serif text-lg"
                disabled={{@controller.transcript.isLoading}}
              />
              <button
                type="submit"
                class="px-8 py-3 bg-ink text-column hover:bg-ink-secondary disabled:bg-ink-tertiary disabled:cursor-not-allowed font-sans font-semibold tracking-wide transition-colors uppercase text-sm"
                disabled={{@controller.transcript.isLoading}}
              >
                {{#if @controller.transcript.isLoading}}
                  Loading…
                {{else}}
                  Read
                {{/if}}
              </button>
            </div>
          </form>
        </div>
      {{/unless}}

      {{! Error Message }}
      {{#if @controller.errorMessage}}
        <div class="mb-6 p-4 bg-accent-bg border-l-4 border-accent">
          <p class="text-accent font-serif">{{@controller.errorMessage}}</p>
        </div>
      {{/if}}

      {{! Loading Spinner }}
      {{#if @controller.transcript.isLoading}}
        <div class="flex items-center justify-center py-16">
          <div
            class="animate-spin rounded-full h-10 w-10 border-2 border-ink border-t-transparent"
          ></div>
          <p class="ml-4 text-ink-secondary font-serif italic text-lg">
            Fetching transcript…
          </p>
        </div>
      {{/if}}

      {{! ═══ Results ═══ }}
      {{#if @controller.groupedTranscript}}

        {{! Sidebar + Article layout }}
        <div class="flex gap-0 items-start">

          {{! TOC Sidebar }}
          <aside class="shrink-0 sticky top-6 self-start mr-4">
            <button
              type="button"
              {{on "click" @controller.toggleToc}}
              class="flex items-center gap-2 px-3 py-2 bg-column border border-rule-dark hover:bg-newsprint transition-colors text-sm font-sans font-medium text-ink w-full"
            >
              {{#if @controller.tocOpen}}
                <PhSidebar @size="16" /><span>Hide</span>
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
          <div class="flex-1 min-w-0 column-rule">

            {{! Headline + Back Button }}
            <div class="mb-4 flex items-start justify-between gap-4">
              {{#if @controller.videoTitle}}
                <h2
                  class="text-3xl font-headline font-black text-ink leading-tight min-w-0"
                >{{@controller.videoTitle}}</h2>
              {{/if}}
              <button
                type="button"
                {{on "click" @controller.clearTranscript}}
                class="text-sm text-ink-tertiary hover:text-accent transition-colors font-sans shrink-0 whitespace-nowrap mt-1"
              >
                <PhArrowLeft @size="14" class="inline" />
                New search
              </button>
            </div>

            {{! Transcript Article }}
            <article class="bg-column border border-rule-dark p-8 relative">
              {{#each @controller.groupedTranscript as |chapter index|}}
                {{! Ornamental divider between chapters (not before first) }}
                {{#unless (isFirstChapter index)}}
                  <div class="section-ornament"></div>
                {{/unless}}

                <section id="chapter-{{index}}" class="scroll-mt-4">
                  {{! Chapter heading with decorative rules }}
                  <h3
                    class="text-xl font-headline font-bold text-ink mb-1 flex items-baseline gap-3"
                  >
                    {{chapter.title}}
                    <span
                      class="text-xs font-normal text-ink-tertiary font-mono"
                    >{{formatTime chapter.startTime}}</span>
                  </h3>
                  <div class="border-t-2 border-ink"></div>
                  <div class="border-t border-ink mt-0.5 mb-4"></div>

                  {{! Body text — first chapter gets drop-cap styling }}
                  <div
                    class="text-ink-secondary font-serif leading-[1.8] space-y-4 text-[1.0625rem]
                      {{if (isFirstChapter index) 'article-body'}}"
                  >
                    {{#each (speakerLines chapter.segments) as |line|}}
                      <p>{{line}}</p>
                    {{/each}}
                  </div>
                </section>
              {{/each}}
            </article>

            {{! ═══ Stats Bar — after the article ═══ }}
            {{#if @controller.transcriptStats}}
              <div class="bg-column border border-rule-dark p-6 mt-6">
                <h2
                  class="text-xs font-sans font-bold text-ink-tertiary uppercase tracking-widest mb-4 border-b border-rule pb-2"
                >Transcript Statistics</h2>
                <div class="grid grid-cols-3 gap-4">
                  <div class="text-center">
                    <div
                      class="text-4xl font-headline font-bold text-ink"
                    >{{@controller.transcriptStats.wpm}}</div>
                    <div
                      class="text-xs text-ink-tertiary font-sans uppercase tracking-wider mt-1"
                    >Words / min</div>
                  </div>
                  <div class="text-center stat-divider">
                    <div
                      class="text-4xl font-headline font-bold text-ink"
                    >{{@controller.transcriptStats.totalWords}}</div>
                    <div
                      class="text-xs text-ink-tertiary font-sans uppercase tracking-wider mt-1"
                    >Total words</div>
                  </div>
                  <div class="text-center stat-divider">
                    <div
                      class="text-4xl font-headline font-bold text-ink"
                    >{{formatTime
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

      {{! Footer }}
      <footer class="mt-12 pt-4 border-t border-rule text-center">
        <p class="dateline">The Transcript Viewer ·
          {{currentYear}}
          · All rights reserved</p>
      </footer>

    </div>
  </div>

  {{outlet}}
</template>
