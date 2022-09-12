// Combined from
// https://github.com/systemsoverload/monaco-languages-extended/blob/d20799d42bab32d71d87cc90bc3911b7aae1bb20/src/standard-tokens/elixir/elixir.js
// https://github.com/elixir-lsp/vscode-elixir-ls/blob/b914752293ed2416a42bfbf107aec8893c1cc3e5/elixir-language-configuration.json
export const lang = {
  defaultToken: '',
  tokenPostfix: '.elixir',
  keywords: [
    'after', 'and', 'bc', 'case', 'catch', 'cond', 'defcallback',
    'defdelegate', 'defexception', 'defguardp?', 'defimpl', 'defmodule',
    'defoverridable', 'defprotocol', 'defrecordp?', 'defstruct', 'do', 'else',
    'end', 'exit', 'fn', 'for', 'if', 'in', 'lc', 'not', 'or', 'quote',
    'raise', 'receive', 'rescue', 'super', 'throw', 'try', 'unless', 'unquote',
    'when', 'with',
  ],


  operators: [
    '!==?', '&&&', '*', '**', '+', '++', '-', '--', '->', '..', '/', '::',
    '<-', '<<', '<<<', '<<~', '<=?', '<>', '<|>', '<~', '<~>', '=', '===?',
    '=>', '=~', '>=?', '>>', '>>>', '\\', '|', '|>', '~>', '~>>', '~~~',
  ],

  symbols:  /[@=><!~?:&|+\-*\/\^%,.]+/,
  escapes: /(\\[uU]|[xX])?{.+}/,

  tokenizer: {
    root: [
      [/[a-z_$][\w$]*/, { cases: { '@keywords': 'keyword',
                                   '@default': 'identifier' } }],
      // variables
      [/[A-Z][\w\$]*/, 'type.identifier' ],

      // atoms
      [/(?:[^\W])?:\w+/, 'variable'],

      //attributes
      [/@\w+/, 'constant'],

      // numbers
      [/\d*\.\d+([eE][\-+]?\d+)?/,   'number.float'],
      [/0[xX][0-9a-fA-F]+[lL]?/,     'number.hex'],
      [/0[bB][0-1]+[lL]?/,           'number.binary'],
      [/(0[oO][0-7]+|0[0-7]+)[lL]?/, 'number.octal'],
      [/(0|[1-9]\d*)[lL]?/,          'number'],

      // codepoint
      [/\?[a-zA-Z]/, 'string'],

      //commments
      [/#(.+)?/, 'comment'],

      //strings
      [/"/, 'string', '@string' ],

      //char list
      [/'/, 'string', '@charlist'],

      // delimiters and operators
      [/[{}()\[\]]/, '@brackets'],
      [/[<>](?!@symbols)/, '@brackets'],
      [/@symbols/, { cases: { '@operators': 'operator',
                              '@default'  : '' } } ],

      // whitespace
      { include: '@whitespace' },

    ],
    charlist: [
      [/[^\']+/, 'string'],
      [/'/, 'string', '@pop' ]
    ],
    string: [
      [/[^\"]+/,  'string'],
      [/@escapes/, 'string.escape'],
      [/\\./,      'string.escape.invalid'],
      [/"/,        'string', '@pop' ]
    ],

    whitespace: [
      [/[ \t\r\n]+/, 'white']
    ],
  },
}

export const config = {
  "comments": {
    "lineComment": "#",
    "blockComment": [ "=begin", "=end" ]
  },
  "brackets": [
    ["{", "}"],
    ["[", "]"],
    ["(", ")"]
  ],
  "autoClosingPairs": [
    { open: "{",  close: "}" },
    { open: "[",  close: "]" },
    { open: "(",  close: ")" },
    { open: "\"", close: "\"", notIn: ["string"] },
    { open: "'",  close: "'", notIn: ["string"] },
    { open: "`",  close: "`", notIn: ["string"] }
  ],
  "surroundingPairs": [
    ["{", "}"],
    ["[", "]"],
    ["(", ")"],
    ["\"", "\""],
    ["'", "'"],
    ["`", "`"]
  ],
  "indentationRules": {
    "increaseIndentPattern": "^\\s*((begin|class|(private|protected)\\s+def|def|else|elsif|ensure|for|if|module|rescue|unless|until|when|while|case)|([^#]*\\sdo\\b)|([^#]*=\\s*(case|if|unless)))\\b([^#\\{;]|(\"|'|\/).*\\4)*(#.*)?$",
    "decreaseIndentPattern": "^\\s*([}\\]]([,)]?\\s*(#|$)|\\.[a-zA-Z_]\\w*\\b)|(end|rescue|ensure|else|elsif|when)\\b)"
  }
}
