local M = {}

M.config = {
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
}

--- Save modified buffers and set directory to file location
function M.pre_run()
  vim.cmd("wall")
  vim.cmd("lcd %:p:h")
end

--- Toggle split layout (code | inp + out)
function M.toggle_layout()
  local inp_name = M.config.input_file
  local out_name = M.config.output_file
  local inp_win, out_win

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")

      if name == inp_name then
        inp_win = win
      elseif name == out_name then
        out_win = win
      end
    end
  end

  if inp_win or out_win then
    if inp_win and vim.api.nvim_win_is_valid(inp_win) then
      vim.api.nvim_win_close(inp_win, true)
    end
    if out_win and vim.api.nvim_win_is_valid(out_win) then
      vim.api.nvim_win_close(out_win, true)
    end
    return
  end

  if M.config.auto_create_files then
    if vim.fn.filereadable(inp_name) == 0 then
      vim.fn.writefile({}, inp_name)
    end
    if vim.fn.filereadable(out_name) == 0 then
      vim.fn.writefile({}, out_name)
    end
  else
    if vim.fn.filereadable(inp_name) == 0 then
      vim.notify(inp_name .. " file not found", vim.log.levels.ERROR, { title = "cprun.nvim" })
      return
    end
    if vim.fn.filereadable(out_name) == 0 then
      vim.notify(out_name .. " file not found", vim.log.levels.ERROR, { title = "cprun.nvim" })
      return
    end
  end

  local code_win = vim.api.nvim_get_current_win()

  vim.cmd("vsplit " .. vim.fn.fnameescape(inp_name))

  local total_cols = vim.o.columns
  local target_width = math.floor(total_cols * M.config.layout_width)
  vim.cmd("vertical resize " .. target_width)

  vim.cmd("split " .. vim.fn.fnameescape(out_name))

  if vim.api.nvim_win_is_valid(code_win) then
    vim.api.nvim_set_current_win(code_win)
  end
end

local function refresh_buffer(file_name)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
      if name == file_name then
        vim.api.nvim_buf_call(buf, function()
          vim.cmd("silent checktime")
          vim.cmd("silent edit!")
        end)
      end
    end
  end
end

local function execute_with_redirection(compiler, std_ver, flag_list)
  M.pre_run()

  local file = vim.fn.expand("%:p")
  local exec = vim.fn.expand("%:p:r")

  if file == "" then
    vim.notify("No valid C++ file to compile", vim.log.levels.ERROR, { title = "cprun.nvim" })
    return
  end

  local inp = M.config.input_file
  local out = M.config.output_file

  if vim.fn.filereadable(inp) == 0 then
    vim.fn.writefile({}, inp)
  end
  if vim.fn.filereadable(out) == 0 then
    vim.fn.writefile({}, out)
  end

  local flags = table.concat(flag_list, " ")
  local compile_cmd = string.format("%s -std=%s %s %s -o %s", compiler, std_ver, flags, vim.fn.shellescape(file), vim.fn.shellescape(exec))

  local compile_out = vim.fn.system(compile_cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("Compilation Error:\n" .. compile_out, vim.log.levels.ERROR, { title = "cprun.nvim" })
    return
  end

  local hrtime = (vim.uv and vim.uv.hrtime) or vim.loop.hrtime
  local start_time = hrtime()

  local run_cmd = string.format("%s < %s > %s 2>&1", vim.fn.shellescape(exec), vim.fn.shellescape(inp), vim.fn.shellescape(out))
  vim.fn.system(run_cmd)
  local exit_code = vim.v.shell_error

  local elapsed_ms = (hrtime() - start_time) / 1e6

  refresh_buffer(out)

  local time_str
  if elapsed_ms < 1000 then
    time_str = string.format("%dms", math.floor(elapsed_ms + 0.5))
  else
    time_str = string.format("%.2fs", elapsed_ms / 1000)
  end

  if exit_code ~= 0 then
    vim.notify(string.format("Runtime Error (exit code %d) [%s]", exit_code, time_str), vim.log.levels.WARN, { title = "cprun.nvim" })
  else
    vim.notify(string.format("✓ Ran in %s", time_str), vim.log.levels.INFO, { title = "cprun.nvim" })
  end
end

--- Fast compile & interactive run in terminal split
function M.run_fast()
  M.pre_run()

  local file = vim.fn.expand("%:p")
  local exec = vim.fn.expand("%:p:r")

  if file == "" then
    vim.notify("No valid C++ file to compile", vim.log.levels.ERROR, { title = "cprun.nvim" })
    return
  end

  local compiler = M.config.compiler
  local std = M.config.cpp_std
  local flags = table.concat(M.config.fast_flags, " ")
  local compile_cmd = string.format("%s -std=%s %s %s -o %s", compiler, std, flags, vim.fn.shellescape(file), vim.fn.shellescape(exec))

  local compile_out = vim.fn.system(compile_cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("Compilation Error:\n" .. compile_out, vim.log.levels.ERROR, { title = "cprun.nvim" })
    return
  end

  local run_cmd = vim.fn.shellescape(exec)

  vim.cmd("botright split")
  vim.cmd("resize " .. M.config.term_height)
  vim.cmd("terminal " .. run_cmd)
  vim.cmd("startinsert")
end

--- Compile with warnings and run redirecting inp -> stdin and stdout -> out
function M.run_warnings()
  execute_with_redirection(M.config.compiler, M.config.cpp_std, M.config.flags)
end

--- Compile with AddressSanitizer (ASan) and run redirecting inp -> stdin and stdout -> out
function M.run_asan()
  execute_with_redirection(M.config.asan_compiler, M.config.cpp_std, M.config.asan_flags)
end

--- Setup plugin configuration, autocmds, and keymaps
function M.setup(opts)
  if opts then
    M.config = vim.tbl_deep_extend("force", M.config, opts)
  end

  if M.config.auto_save then
    local group = vim.api.nvim_create_augroup("cprun_autosave", { clear = true })
    vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
      group = group,
      pattern = { M.config.input_file, M.config.output_file },
      callback = function()
        if vim.bo.modified then
          vim.cmd("silent write")
        end
      end,
    })
  end

  if M.config.keymaps.enable then
    local group = vim.api.nvim_create_augroup("cprun_keymaps", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = "cpp",
      callback = function(ev)
        local km = M.config.keymaps
        local opts_base = { buffer = ev.buf, silent = true }

        if km.toggle_layout then
          vim.keymap.set("n", km.toggle_layout, M.toggle_layout, vim.tbl_extend("force", opts_base, { desc = "CP toggle layout" }))
        end
        if km.run_fast then
          vim.keymap.set({ "n", "i" }, km.run_fast, M.run_fast, vim.tbl_extend("force", opts_base, { desc = "CP run fast terminal" }))
        end
        if km.run_asan then
          vim.keymap.set({ "n", "i" }, km.run_asan, M.run_asan, vim.tbl_extend("force", opts_base, { desc = "CP run ASan" }))
        end
        if km.run_warnings then
          vim.keymap.set({ "n", "i" }, km.run_warnings, M.run_warnings, vim.tbl_extend("force", opts_base, { desc = "CP run with warnings" }))
        end
      end,
    })
  end
end

return M
