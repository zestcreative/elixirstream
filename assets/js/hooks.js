import theme from "./theme"
import { minimalSetup } from "codemirror"
import { EditorView, keymap } from "@codemirror/view"
import { Compartment, EditorState } from "@codemirror/state"
import { StreamLanguage } from "@codemirror/language"
import { indentWithTab } from "@codemirror/commands"
import { elixir } from "codemirror-lang-elixir"
import { oneDark } from '@codemirror/theme-one-dark'
import debounce from 'lodash.debounce'

const editorTheme = new Compartment()
const lightTheme = EditorView.baseTheme({})

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

hooks.CodeMirror = {
  mounted() {
    const replace = this.el.dataset.mountReplaceSelector;
    const replaceEl = this.el.querySelector(replace)
    const where = this.el.dataset.mountSelector;
    const mountEl = this.el.querySelector(where)
    const cmTheme = theme.displayedTheme() === "light" ? lightTheme : oneDark

    this.editor = new EditorView({
      doc: replaceEl.value,
      extensions: [
        minimalSetup,
        EditorState.tabSize.of(2),
        keymap.of([indentWithTab]),
        StreamLanguage.define(elixir),
        editorTheme.of(cmTheme),
        EditorView.updateListener.of(debounce((v) => {
          if (v.docChanged) {
            this.pushEvent("code-updated", v.state.doc.text.join("\n"))
          }
        }, 500))
      ],
      parent: mountEl
    })
    replaceEl.classList.add("hidden")
    mountEl.classList.remove("hidden")
    this.themeListener = document.addEventListener('theme', (e) => {
      const cmTheme = e.detail === 'dark' ? oneDark : lightTheme
      this.editor.dispatch({ effects: editorTheme.reconfigure(cmTheme) })
    })
  },
  destroyed() {
    if (this.themeListener) document.removeEventListener(this.themeListener)
    if (this.editor) this.editor.destroy()
  }
}

export default hooks;
