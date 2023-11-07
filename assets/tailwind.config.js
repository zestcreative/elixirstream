const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    '../lib/utility_web/**/*.*ex',
    './js/**/*.js'
  ],
  darkMode: 'class',
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', 'Inter', ...defaultTheme.fontFamily.sans],
        mono: ['Fira Code VF', 'Fira Code', ...defaultTheme.fontFamily.mono],
        brand: ['Fira Sans', ...defaultTheme.fontFamily.sans],
      },
      colors: {
        brand: {
          '50': '#FDFAFF',
          '100': '#F1E3FC',
          '200': '#DAB4F8',
          '300': '#C285F4',
          '400': '#AB56F0',
          '500': '#9428EC',
          '600': '#7A12CE',
          '700': '#5E0E9F',
          '800': '#420A70',
          '900': '#270642'
        },
        accent: {
          '50': '#EDFAFA',
          '100': '#E6FFFA',
          '200': '#B2F5EA',
          '300': '#81E6D9',
          '400': '#4FD1C5',
          '500': '#38B2AC',
          '600': '#319795',
          '700': '#2C7A7B',
          '800': '#285E61',
          '900': '#234E52'
        }
      },
      typography: (theme) => ({
        DEFAULT: {
          css: {
            'a': {
              textDecoration: 'none'
            }
          }
        },
        invert: {
          css: {
            '[class~="lead"]': {
              color: theme('colors.gray.200'),
            },
            'a': {
              color: theme('colors.white'),
              textDecoration: 'none'
            },
            'strong': {
              color: theme('colors.white'),
            },
            'ol > li::before': {
              color: theme('colors.gray.300'),
            },
            'ul > li::before': {
              backgroundColor: theme('colors.gray.600'),
            },
            'hr': {
              borderColor: theme('colors.gray.200'),
            },
            'blockquote': {
              color: theme('colors.gray.200'),
              borderLeftColor: theme('colors.gray.600'),
            },
            'figure figcaption': {
              color: theme('colors.gray.300'),
            },
            'code': {
              color: theme('colors.white'),
            },
            'a code': {
              color: theme('colors.white'),
            },
            'pre': {
              color: theme('colors.gray.200'),
              backgroundColor: theme('colors.gray.800'),
            },
            'thead': {
              borderBottomColor: theme('colors.gray.400'),
            },
            'tbody tr': {
              borderBottomColor: theme('colors.gray.600'),
            },
            '--tw-prose-body': theme('colors.gray.200'),
            '--tw-prose-headings': theme('colors.gray.300'),
            '--tw-prose-captions': theme('colors.gray.500'),
            '--tw-prose-thead': theme('colors.gray.300'),
          },
        },
      }),
    },
  },
  variants: {
    extend: {
      opacity: ['disabled'],
      cursor: ['disabled'],
      typography: ['dark']
    }
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/aspect-ratio')
  ],
}
