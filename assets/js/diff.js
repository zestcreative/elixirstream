/*
Make it possible to click line numbers to update the address bar to a
link directly to that line.
*/
if (location.hash) {
  document.getElementById(location.hash.replace("#", "")).classList.add("selected")
}

const lines = document.querySelectorAll(".ghd-line-number")
lines.forEach(line => {
  line.addEventListener("click", _e => {
    const parent = line.parentNode

    if (parent && parent.id) {
      document.querySelectorAll(".ghd-line.selected").forEach(line => {
        line.classList.remove("selected")
      })

      parent.classList.add("selected")

      history.replaceState(null, null, '#' + parent.id)
    }
  })
})

const submitBtn = document.getElementById("submit-diff")

if (submitBtn) {
  submitBtn.addEventListener("click", _e => {
    const outputMain = document.getElementById("output-main")
    const outputOne = document.getElementById("output-runner-1")
    const outputTwo = document.getElementById("output-runner-2")

    if (outputMain) {
      while (outputTwo.firstChild) { outputTwo.removeChild(outputTwo.firstChild) }
      while (outputOne.firstChild) { outputOne.removeChild(outputOne.firstChild) }
      while (outputMain.firstChild) { outputMain.removeChild(outputMain.firstChild) }
    }
  })
}

const fileHeaders = document.querySelectorAll(".ghd-file-header")
fileHeaders.forEach(header => {
  header.addEventListener("click", _e => {
    const parent = header.parentNode

    parent.querySelectorAll(".ghd-diff").forEach(diff => {
      diff.classList.toggle("hidden")
    })
    header.classList.toggle("collapsed") && scrollIfNeeded(header)
  })
})

const scrollIfNeeded = elem => {
  elem.getBoundingClientRect().top < 0 && elem.scrollIntoView(true)
}
