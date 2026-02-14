/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./app/**/*.{js,ts,hbs,gjs,gts}'],
  theme: {
    extend: {
      colors: {
        newsprint: 'var(--color-newsprint)',
        column: 'var(--color-column)',
        ink: {
          DEFAULT: 'var(--color-ink)',
          secondary: 'var(--color-ink-secondary)',
          tertiary: 'var(--color-ink-tertiary)',
        },
        rule: {
          DEFAULT: 'var(--color-rule)',
          dark: 'var(--color-rule-dark)',
        },
        accent: {
          DEFAULT: 'var(--color-accent)',
          hover: 'var(--color-accent-hover)',
          bg: 'var(--color-accent-bg)',
        },
      },
      fontFamily: {
        headline: ['Playfair Display', 'Georgia', 'Times New Roman', 'serif'],
        serif: ['Lora', 'Georgia', 'Times New Roman', 'Times', 'serif'],
        sans: ['Inter', 'ui-sans-serif', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'ui-monospace', 'SFMono-Regular', 'monospace'],
      },
    },
  },
  plugins: [],
};
