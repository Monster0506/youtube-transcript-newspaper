export default {
  extends: ['stylelint-config-standard'],
  rules: {
    'at-rule-no-unknown': [
      true,
      {
        ignoreAtRules: ['tailwind', 'source', 'theme'],
      },
    ],
    // Tailwind v4 uses bare @import 'tailwindcss' (not url())
    'import-notation': 'string',
    // @source follows @import with no blank line needed
    'at-rule-empty-line-before': [
      'always',
      {
        except: ['first-nested', 'after-same-name'],
        ignore: [
          'after-comment',
          'blockless-after-same-name-blockless',
          'blockless-after-blockless',
        ],
      },
    ],
  },
};
