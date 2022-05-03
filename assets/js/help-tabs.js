window.addEventListener("helpTab", (event) => {
  const help = event.target.dataset.tab || event.target.value

  document.querySelectorAll('div[data-tab]').forEach(el => {
    if(el.id === `help-${help}-tab`) {
      el.classList.remove("hidden")
    } else {
      el.classList.add("hidden")
    }
  })

  const activeBtnClasses = ["border-brand-300", "text-gray-700", "dark:text-gray-300"]
  document.querySelectorAll('button[data-tab]').forEach(el => {
    if(el.id === `help-${help}-btn`) {
      activeBtnClasses.forEach(cls => el.classList.add(cls))
    } else {
      activeBtnClasses.forEach(cls => el.classList.remove(cls))
    }
  })
})
