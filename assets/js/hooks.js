let hooks = {};

hooks.MaskFlags = {
  mounted() {
    this.el.addEventListener("input", _event => {
      let masked = this.el.value
      masked = masked.replace(/[^Ufimsux]+/g, "");
      masked = masked.split('').filter((item, i, ar) => ar.indexOf(item) === i).join('');
      this.el.value = masked;
    });
  },
  unique_char(str1) {
    var str = str1;
    var uniql = "";
    for (var x=0; x < str.length; x++) {
      if(uniql.indexOf(str.charAt(x))==-1) {
        uniql += str[x];
      }
    }
    return uniql;
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
