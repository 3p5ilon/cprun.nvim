# cprun.nvim ⚡

Minimal, fast C++ competitive programming workflow plugin for Neovim.

## ⚡ Features

- **Split Layout (`<leader>cp`)**: Toggle `inp` and `out` side-by-side panes (~35% width). Auto-creates files if missing.
- **Auto-Save**: Saves `inp` and `out` automatically on edit (`TextChanged`, `InsertLeave`).
- **Fast Run (`<F6>`)**: Compiles (`g++ -O2`) and opens an interactive bottom terminal split.
- **Run with Warnings (`<F8>`)**: Compiles (`g++ -Wall -Wextra -Wshadow -O2`) and runs silently with `< inp > out`.
- **AddressSanitizer (`<F7>`)**: Compiles (`clang++ -fsanitize=address`) to catch memory leaks and out-of-bounds errors.
- **Precise Timing**: Displays execution time in milliseconds (`42ms`) or seconds (`1.85s`).

## 📦 Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "username/cprun.nvim",
  ft = "cpp",
  opts = {},
}
```

## ⚙️ Default Configuration

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

## ⌨️ Default Keymaps

| Keymap | Mode | Command | Description |
| :--- | :--- | :--- | :--- |
| `<leader>cp` | `Normal` | `:CPToggle` | Toggle `inp` / `out` layout |
| `<F6>` | `Normal`, `Insert` | `:CPRunFast` | Fast compile & open interactive terminal |
| `<F7>` | `Normal`, `Insert` | `:CPRunAsan` | Compile with ASan (`< inp > out`) |
| `<F8>` | `Normal`, `Insert` | `:CPRunWarnings` | Compile with warnings (`< inp > out`) |

## 📄 License

[MIT License](LICENSE)
