export default class MobileNav {
  constructor(id) {
    this.isOpen = false
    this.el = document.getElementById(id);
  }

  init() {
    this.close();
    this.el.addEventListener('keydown', this.shortcuts);
  }

  shortcuts(event) {
    // esc
    if (event.code === 27) this.close()
  }

  close() {
    this.el.classList.add("hidden");
    this.isOpen = false;
  }

  open() {
    this.el.classList.remove("hidden")
    this.isOpen = true;
  }

  toggle() {
    if(this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }
}
