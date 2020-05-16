// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//
import "phoenix_html"
import "./socket"
import topbar from "topbar";

topbar.config({
  barThickness: 2,
  shadowBlur: 5,
  barColors: ["#F56565", "#9B2C2C"],
})

window.addEventListener("phx:page-loading-start", _info => topbar.show());
window.addEventListener("phx:page-loading-stop", _info => topbar.hide());
