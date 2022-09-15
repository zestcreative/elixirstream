import theme from "./theme"
import editorInit from "./code-editor"

let hooks = {};

hooks.RegisterSlash = {
  mounted() {
    const el = this.el
    document.addEventListener("keyup", e => {
      if (e.key !== "/" || e.ctrlKey || e.metaKey) return;
      if (/^(?:input|textarea|select|button)$/i.test(e.target.tagName)) return;

      e.preventDefault();
      el.focus()
    });
  }
}

hooks.HandleScroll = {
  mounted() {
    this.handleEvent("scroll", ({ to }) => {
      if (!to) return
      const el = document.querySelector(to)
      if(el) {
        el.scrollIntoView({ behavior: "smooth" })
        location.hash = to
      } else {
        console.warn(`scroll event did not find ${to} to scroll to`)
      }
    })
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

hooks.ThemeChooser = {
  mounted() {
    theme.init()
  }
}

hooks.MonacoEditor = {
  destroyed() {
    this.editor.unmount()
  },
  mounted() {
    const where = this.el.dataset.mountSelector;
    const mountEl = this.el.querySelector(where)
    if (mountEl) {
      const replace = this.el.dataset.mountReplaceSelector;
      const replaceEl = this.el.querySelector(replace)
      const editorStatus = this.el.dataset.editorStatusSelector
      const editorStatusEl = this.el.querySelector(editorStatus)
      let preferences = {}

      if(this.el.dataset.enableVim === "true") {
        preferences.vim = editorStatusEl
      } else if(this.el.dataset.enableEmacs === "true") {
        preferences.emacs = editorStatusEl
      }

      replaceEl.classList.add("hidden")
      mountEl.classList.remove("hidden")
      const editor = editorInit.mount(mountEl, preferences)
      editor.setValue(replaceEl.value)
      editor.setOnChange({
        callback: (_event) => {
          let payload = editor.instance.getValue()
          replaceEl.value = payload.replace(/\r\n/g, "\n")
          this.pushEvent("code-updated", payload)
        },
        debounceMs: 1000
      })
      this.editor = editor
      this.handleEvent("set_code", ({ code }) => {
        if (this.editor) {
          this.editor.setValue(code)
        }
      })
    } else {
      console.error(`Could not mount Monaco onto ${where}`)
    }

  }
}

export default hooks;
