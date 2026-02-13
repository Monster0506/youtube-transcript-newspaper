/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./app/**/*.{js,ts,hbs,gjs,gts}'],
  theme: {
    extend: {
      colors: {
        newsprint: '#f5f1e8', // aged newsprint page
        column: '#faf8f3', // article column background
        ink: {
          DEFAULT: '#1c1a14', // near-black ink
          secondary: '#48453c', // secondary / byline
          tertiary: '#8c897e', // timestamps, labels
        },
        rule: {
          DEFAULT: '#c8c2b4', // light ruled line
          dark: '#48453c', // heavy ink rule
        },
        accent: {
          DEFAULT: '#8b1a1a', // editorial red
          hover: '#711414',
          bg: '#fdf5f5', // error / alert tint
        },
      },
      fontFamily: {
        serif: ['Georgia', 'Times New Roman', 'Times', 'serif'],
        sans: ['ui-sans-serif', 'system-ui', 'sans-serif'],
        mono: ['ui-monospace', 'SFMono-Regular', 'monospace'],
      },
    },
  },
  plugins: [],
};
