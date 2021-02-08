let hooks = {};

hooks.HandleScroll = {
  mounted() {
    this.handleEvent("scroll", ({to}) => location.hash = to)
  }
}

hooks.MaskFlags = {
  mounted() {
    this.el.addEventListener("input", _event => {
      let masked = this.el.value
      masked = masked.replace(/[^Ufimsux]+/g, "");
      masked = masked.split('').filter((item, i, ar) => ar.indexOf(item) === i).join('');
      this.el.value = masked;
    });
  }
}

hooks.ConfirmBeforeLeave = {
  mounted() {
    window.addEventListener("beforeunload", this.confirm(this.el), false);
  },

  confirm(el) {
    return function(e) {
      e.preventDefault();
      if(el.dataset.isChanged === 'true') {
        if(!confirm("Are you sure you want to leave?")) {
          e.returnValue = '';
        };
      }

      return;
    }
  }
}

hooks.ClipboardCopy = {
  mounted() {
    const el = this.el;
    el.addEventListener("click", (_e) => {
      const targetEl = document.getElementById(el.dataset.target);
      targetEl.select();
      document.execCommand("copy");
      const previousText = el.innerText;
      el.innerText = "Copied!"
      targetEl.selectionStart = targetEl.selectionEnd;
      setTimeout(() => el.innerText = previousText, 5000)
    });
  }
}

export default hooks;
