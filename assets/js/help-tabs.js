window.addEventListener("changeTab", (event) => {
  const target = event.target.dataset.tab || event.target.value
  const group = event.target.dataset.tabGroup

  document.querySelectorAll(`div[data-tab-group="${group}"]`).forEach(el => {
    if(el.id === `tab-${target}-content`) {
      el.classList.remove("hidden")
    } else {
      el.classList.add("hidden")
    }
  })

  document.querySelectorAll(`select[data-tab-group="${group}"]`).forEach(el => {
    el.value = target
  })

  const activeBtnClasses = event.detail.active
  document.querySelectorAll(`button[data-tab-group="${group}"]`).forEach(el => {
    if(el.id === `tab-${target}-btn`) {
      activeBtnClasses.forEach(cls => el.classList.add(cls))
    } else {
      activeBtnClasses.forEach(cls => el.classList.remove(cls))
    }
  })
})
