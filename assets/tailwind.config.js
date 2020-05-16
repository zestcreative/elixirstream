module.exports = {
  purge: [
    "../lib/regex_tester_web/live/**/*.ex",
    "../lib/regex_tester_web/templates/**/*.eex",
    "../lib/regex_tester_web/templates/**/*.leex",
    "../lib/regex_tester_web/views/**/*.ex",
    "../lib/regex_tester_web/components/**/*.ex",
    "./js/**/*.js"
  ],
  theme: {
    extend: {},
  },
  variants: {},
  plugins: [],
}
