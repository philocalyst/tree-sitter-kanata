# tree-sitter-kanata

A [tree-sitter](https://tree-sitter.github.io/tree-sitter/) grammar for
[kanata](https://github.com/jtroo/kanata) keyboard remapper configuration
files (`.kbd`).

The grammar mirrors kanata's own S-expression lexer exactly:

- Atoms terminate only on `(`, `)`, `"`, and whitespace — `C-A-del`, `;foo`,
  `a#b`, and Unicode atoms all parse as single identifiers.
- `;;` line comments (a single `;` is a regular atom character).
- `#| ... |#` block comments (non-nesting, closed at the first `|#`).
- `"..."` strings (no escapes, single-line) and `r#"..."#` raw multiline
  strings (closed at the first `"#`, handled by an external scanner).
- `$var` and `@alias` references, and numbers, are distinct node types for
  precise highlighting.

## Node types

`source_file`, `list`, `identifier`, `number`, `string`, `raw_string`,
`variable_reference`, `alias_reference`, `line_comment`, `block_comment`.

## Editor setup

### Helix

Add to `~/.config/helix/languages.toml`:

```toml
[[language]]
name = "kanata"
scope = "source.kanata"
injection-regex = "kanata"
file-types = ["kbd"]
comment-token = ";;"
block-comment-tokens = { start = "#|", end = "|#" }
indent = { tab-width = 2, unit = "  " }

[language.auto-pairs]
'(' = ')'
'"' = '"'

[[grammar]]
name = "kanata"
source = { git = "https://github.com/postsolar/tree-sitter-kanata", rev = "<commit sha>" }
```

Copy the `queries/` directory to `~/.config/helix/runtime/queries/kanata/`,
then run `hx --grammar fetch && hx --grammar build`.

### Neovim (nvim-treesitter)

```lua
local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
parser_config.kanata = {
  install_info = {
    url = "https://github.com/postsolar/tree-sitter-kanata",
    files = { "src/parser.c", "src/scanner.c" },
    branch = "master",
  },
  filetype = "kbd",
}
vim.filetype.add({ extension = { kbd = "kanata" } })
```

Copy the `queries/` directory to `~/.config/nvim/queries/kanata/`, then run
`:TSInstall kanata`.

## Development

```sh
tree-sitter generate   # regenerate src/ from grammar.js
tree-sitter test       # run test/corpus
tree-sitter parse examples/*.kbd
```
