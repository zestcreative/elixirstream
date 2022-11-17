const colorScheme = document.head.querySelector("meta[name='color-scheme']")
const themeColor = document.head.querySelector("meta[name='theme-color']")
const light = '#7A12CE' // bg-brand-600
const dark = '#420A70' // bg-brand-800

export default {
  updateTheme: function(theme) {
    let changeTo = null
    switch(theme) {
      case "light":
        localStorage.theme = "light"
        if (colorScheme) colorScheme.setAttribute('content', 'light')
        if (themeColor) themeColor.setAttribute('content', light)
        document.documentElement.classList.remove("dark")
        changeTo = 'light'
        break;
      case "dark":
        localStorage.theme = "dark"
        if (colorScheme) colorScheme.setAttribute('content', 'dark')
        if (themeColor) themeColor.setAttribute('content', dark)
        document.documentElement.classList.add("dark")
        changeTo = 'dark'
        break;
      default:
        localStorage.removeItem('theme')
        if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
          document.documentElement.classList.add("dark")
          if (colorScheme) colorScheme.setAttribute('content', 'dark')
          if (themeColor) themeColor.setAttribute('content', dark)
          changeTo = 'dark'
        } else {
          if (colorScheme) colorScheme.setAttribute('content', 'light')
          if (themeColor) themeColor.setAttribute('content', light)
          document.documentElement.classList.remove("dark")
          changeTo = 'light'
        }
        break;
    }
    const event = new CustomEvent('theme', { detail: changeTo })
    document.dispatchEvent(event)
  },
  currentTheme: function() {
    return localStorage.theme || "system"
  },
  displayedTheme: function() {
    if (document.documentElement.classList.contains("dark")) {
      return "dark"
    } else {
      return "light"
    }
  },
  watch: function() {
    window.matchMedia('(prefers-color-scheme: dark)').addListener(e => {
      if (localStorage.theme) return
      if (e.matches) {
        document.documentElement.classList.add('dark')
      } else {
        document.documentElement.classList.remove('dark')
      }
    });
  },
  init: function() {
    const el = document.getElementById("themeChooser")
    if(el) {
      const currentTheme = this.currentTheme()
      const option = document.getElementById(`theme-${currentTheme}`)
      option.selected = currentTheme === option.value

      el.addEventListener('change', (event) => {
        this.updateTheme(event.target.value)
      })
    }
    return this
  }
}
