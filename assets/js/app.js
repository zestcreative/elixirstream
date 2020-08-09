import "phoenix_html"
import "./socket"
import "./loading-bar"
import MobileNav from "./mobile-nav";

window.mobileNav = new MobileNav("mobile-nav")
window.mobileNav.init()
