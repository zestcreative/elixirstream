module.exports = {
  purge: [
    "../lib/utility_web/live/**/*.ex",
    "../lib/utility_web/live/**/*.leex",
    "../lib/utility_web/templates/**/*.eex",
    "../lib/utility_web/templates/**/*.leex",
    "../lib/utility_web/views/**/*.ex",
    "../lib/utility_web/components/**/*.ex",
    "../lib/utility_web/components/**/*.leex",
    "./js/**/*.js"
  ],
  theme: {
    extend: {
      typography: (_theme) => ({
        DEFAULT: {
          css: {
            a: {
              textDecoration: 'none'
            }
          }
        }
      }),
      colors: {
        brand: {
          '100': '#EBF4FF',
          '200': '#C3DAFE',
          '300': '#A3BFFA',
          '400': '#7F9CF5',
          '500': '#667EEA',
          '600': '#5A67D8',
          '700': '#4C51BF',
          '800': '#434190',
          '900': '#3C366B'
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
    }
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/aspect-ratio')
  ],
}
