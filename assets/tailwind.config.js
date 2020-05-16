module.exports = {
  purge: [
    "../lib/utility_web/live/**/*.ex",
    "../lib/utility_web/templates/**/*.eex",
    "../lib/utility_web/templates/**/*.leex",
    "../lib/utility_web/views/**/*.ex",
    "../lib/utility_web/components/**/*.ex",
    "./js/**/*.js"
  ],
  theme: {
    extend: {},
  },
  variants: {},
  plugins: [],
}
