local M = {}

M.defaults = {
  compiler = "g++",
  asan_compiler = "clang++",
  cpp_std = "c++17",
  flags = { "-Wall", "-Wextra", "-Wshadow", "-O2" },
  fast_flags = { "-O2" },
  asan_flags = { "-Wall", "-Wextra", "-Wshadow", "-fsanitize=address", "-O2" },
  term_height = 10,
  qf_height = 10,
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
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
  return M.options
end

return M

