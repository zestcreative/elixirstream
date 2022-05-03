export default {
  updateTheme: function(theme) {
    switch(theme) {
      case "light":
        localStorage.theme = "light"
        document.documentElement.classList.remove("dark")
        break;
      case "dark":
        localStorage.theme = "dark"
        document.documentElement.classList.add("dark")
        break;
      default:
        localStorage.removeItem('theme')
        if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
          document.documentElement.classList.add("dark")
        } else {
          document.documentElement.classList.remove("dark")
        }
        break;
    }
  },
  currentTheme: function() {
    return localStorage.theme || "system"
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
