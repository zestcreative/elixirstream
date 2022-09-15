import * as monaco from "monaco-editor"
import { initVimMode } from "monaco-vim"
import { EmacsExtension } from "monaco-emacs"
import { config, lang } from "./monaco-elixir-syntax"
import debounce from 'lodash.debounce'

monaco.languages.register({ id: "elixir" })
monaco.languages.setMonarchTokensProvider("elixir", lang)
monaco.languages.setLanguageConfiguration("elixir", config)

export default {
  instance: null,
  setOnChange: function({ callback: cb, debounceMs: waitMs }) {
    const debounced = debounce(cb, waitMs, { 'maxWait': 3000 })
    this.instance.getModel().onDidChangeContent(debounced)
  },
  getValue: function() {
    this.instance.getModel().getValue()
  },
  setValue: function(value) {
    this.instance.getModel().setValue(value)
  },
  unmount: function() {
    if(this.instance) {
      this.instance.dispose()
    }
  },
  mount: function(el, preferences) {
    // https://microsoft.github.io/monaco-editor/api/interfaces/monaco.editor.ieditoroptions.html
    const instance = monaco.editor.create(el, {
      language: "elixir",
      automaticLayout: true,
      codeLens: false,
      contextmenu: false,
      extraEditorClassName: "bg-white",
      fontFamily: "Fira Code, JetBrains Mono, Droid Sans Mono, monospace",
      fontLigatures: true,
      formatOnPaste: true,
      formatOnType: true,
      hideCursorInOverviewRuler: true,
      minimap: { enabled: false },
      overviewRulerBorder: false,
      overviewRulerLanes: 0,
      padding: { top: 20, bottom: 20 },
      quickSuggestions: false,
      renderLineHighlight: "none",
      rulers: 80,
      scrollBeyondLastLine: false,
      scrollbar: { alwaysConsumeMouseWheel: false },
      snippetSuggestions: "none",
      wordBasedSuggestions: false
    });

    instance.getModel().updateOptions({
      detectIndentation: false,
      tabSize: 2
    })

    if(preferences.vim) {
      const { vim: statusNode } = preferences
      initVimMode(instance, statusNode)
    } else if(preferences.emacs) {
      const { emacs: statusNode } = preferences
      const emacsMode = new EmacsExtension(instance)
      emacsMode.onDidMarkChange((ev) => {
        statusNode.textContent = ev ? 'Mark Set!' : 'Mark Unset'
      })
      emacsMode.onDidChangeKey((str) => {
        statusNode.textContent = str
      })
      emacsMode.start()
    }

    this.instance = instance
    return this
  }
}
