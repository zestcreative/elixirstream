module.exports = {
  plugins: {
    "postcss-import": {},
    "tailwindcss": {},
    "postcss-preset-env": {
      browsers: "last 2 versions",
      features: {
        // https://github.com/tailwindcss/tailwindcss/issues/1190
        'focus-within-pseudo-class': false
      }
    }
  }
}
