module.exports = {
  purge: [
    '../lib/utility_web/live/**/*.ex',
    '../lib/utility_web/live/**/*.leex',
    '../lib/utility_web/templates/**/*.eex',
    '../lib/utility_web/templates/**/*.leex',
    '../lib/utility_web/views/**/*.ex',
    '../lib/utility_web/components/**/*.ex',
    '../lib/utility_web/components/**/*.leex',
    './js/**/*.js'
  ],
  darkMode: 'class',
  theme: {
    extend: {
      typography: (theme) => ({
        dark: {
          css: {
            color: theme('colors.gray.300'),
            '[class~="lead"]': {
              color: theme('colors.gray.200'),
            },
            a: {
              color: theme('colors.white'),
              textDecoration: 'none'
            },
            strong: {
              color: theme('colors.white'),
            },
            'ol > li::before': {
              color: theme('colors.gray.300'),
            },
            'ul > li::before': {
              backgroundColor: theme('colors.gray.600'),
            },
            hr: {
              borderColor: theme('colors.gray.200'),
            },
            blockquote: {
              color: theme('colors.gray.200'),
              borderLeftColor: theme('colors.gray.600'),
            },
            h1: {
              color: theme('colors.white'),
            },
            h2: {
              color: theme('colors.white'),
            },
            h3: {
              color: theme('colors.white'),
            },
            h4: {
              color: theme('colors.white'),
            },
            'figure figcaption': {
              color: theme('colors.gray.300'),
            },
            code: {
              color: theme('colors.white'),
            },
            'a code': {
              color: theme('colors.white'),
            },
            pre: {
              color: theme('colors.gray.200'),
              backgroundColor: theme('colors.gray.800'),
            },
            thead: {
              color: theme('colors.white'),
              borderBottomColor: theme('colors.gray.400'),
            },
            'tbody tr': {
              borderBottomColor: theme('colors.gray.600'),
            },
          },
        },
        DEFAULT: {
          css: {
            a: {
              textDecoration: 'none'
            }
          }
        }
      }),
      colors: {
        // brand: {
        //   '100': '#EBF4FF',
        //   '200': '#C3DAFE',
        //   '300': '#A3BFFA',
        //   '400': '#7F9CF5',
        //   '500': '#667EEA',
        //   '600': '#5A67D8',
        //   '700': '#4C51BF',
        //   '800': '#434190',
        //   '900': '#3C366B'
        // },
        brand: {
          DEFAULT: '#9428EC',
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
      }
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
    require('@tailwindcss/aspect-ratio'),
    require("@tailwindcss/line-clamp")
  ],
}
