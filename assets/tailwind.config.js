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
    extend: {},
  },
  variants: {},
  plugins: [
    require('@tailwindcss/ui')({
      layout: 'sidebar',
    })
  ],
}
