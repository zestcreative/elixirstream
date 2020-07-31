import topbar from "topbar";

topbar.config({
  barThickness: 2,
  shadowBlur: 5,
  barColors: ["#F56565", "#9B2C2C"],
})

window.addEventListener("phx:page-loading-start", _info => topbar.show());
window.addEventListener("phx:page-loading-stop", _info => topbar.hide());
