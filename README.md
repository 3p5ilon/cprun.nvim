# cprun.nvim

A minimal, fast Neovim plugin for competitive programming in C++.

Compile, run, and check output — nothing else.

<img alt="cprun demo img" src="https://github.com/user-attachments/assets/93896ade-dc84-404a-b875-b90696ce12dd" />

## Features

- **Split layout** (`<leader>cp`) — toggles `inp`/`out` side-by-side panes. Auto-creates files if missing.
- **Auto-save** — `inp` and `out` save automatically as you edit them.
- **Fast run** (`<F6>`) — compiles with `g++ -O2`, opens an interactive terminal.
- **Warnings build** (`<F8>`) — compiles with `-Wall -Wextra -Wshadow -O2`, runs silently via `inp` → `out`.
- **AddressSanitizer build** (`<F7>`) — compiles with `-fsanitize=address`, catches memory bugs.
- **Clean timing** — shows run time as `42ms` or `1.85s`.

## Install

**lazy.nvim**:

```lua
{
  "username/cprun.nvim",
  ft = "cpp",
  opts = {},
}
```

packer.nvim:

```lua
use({
  "username/cprun.nvim",
  ft = "cpp",
  config = function()
    require("cprun").setup({})
  end,
})
```

## Configuration

```lua
require("cprun").setup({
  compiler = "g++",
  asan_compiler = "clang++",
  cpp_std = "c++17",
  flags = { "-Wall", "-Wextra", "-Wshadow", "-O2" },
  fast_flags = { "-O2" },
  asan_flags = { "-Wall", "-Wextra", "-Wshadow", "-fsanitize=address", "-O2" },
  term_height = 12,
  layout_width = 0.35,
  input_file = "inp",
  output_file = "out",
  auto_create_files = true,
  auto_save = true,
  keymaps = {
    enable = true,
    toggle_layout = "<leader>cp",
    run_fast = "<F6>",
    run_asan = "<F7>",
    run_warnings = "<F8>",
  },
})
```

## Keymaps

| Key          | Command          | What it does                                 |
| ------------ | ---------------- | -------------------------------------------- |
| `<leader>cp` | `:CPToggle`      | Toggle `inp`/`out` layout                    |
| `<F6>`       | `:CPRunFast`     | Fast compile + interactive terminal          |
| `<F7>`       | `:CPRunAsan`     | Compile with ASan, run via `inp` → `out`     |
| `<F8>`       | `:CPRunWarnings` | Compile with warnings, run via `inp` → `out` |

Any keymap can be remapped or set to `false`.

## Snippets (optional, not bundled)

cprun.nvim doesn't include snippets. You can use [LuaSnip](https://github.com/L3MON4D3/LuaSnip) for that — drop this in `~/.config/nvim/lua/snippets/cpp.lua` and `require("snippets.cpp")` from your `init.lua`:

```lua
local ls = require("luasnip")
local s, t, i = ls.snippet, ls.text_node, ls.insert_node

ls.add_snippets("cpp", {
  s("tem", {
    t({
      "#include <bits/stdc++.h>",
      "using namespace std;",
      "",
      "int main() {",
      "    ios_base::sync_with_stdio(false);",
      "    cin.tie(NULL);",
      "",
      "    ",
    }),
    i(1),
    t({ "", "    return 0;", "}", "" }),
  }),
})
```

See the [LuaSnip docs](https://github.com/L3MON4D3/LuaSnip/blob/master/DOC.md) for more.

## Philosophy

This plugin intentionally does **not** include: multiple testcase management, verdict checking, online-judge integration, or snippets.
For any of those, check out [competitest.nvim](https://github.com/xeluxee/competitest.nvim) — a much more feature-complete tool. cprun.nvim exists for people who just want the fast compile-run loop and nothing more.

## License

[MIT](LICENSE)
