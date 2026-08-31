local layout = require("cprun.layout")

local M = {}
local is_win = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1

local function is_cpp_buf(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  return name ~= "" and (vim.bo[buf].filetype == "cpp" or name:match("%.cpp$") or name:match("%.cc$") or name:match("%.cxx$"))
end

local function get_cpp_and_exec()
  local cur_buf = vim.api.nvim_get_current_buf()
  local file = is_cpp_buf(cur_buf) and vim.api.nvim_buf_get_name(cur_buf) or ""

  if file == "" then
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local b = vim.api.nvim_win_get_buf(win)
      if is_cpp_buf(b) then
        file = vim.api.nvim_buf_get_name(b)
        break
      end
    end
  end

  if file == "" then
    vim.notify("No valid C++ file found", vim.log.levels.ERROR, { title = "cprun.nvim" })
    return nil, nil, nil
  end

  local dir = vim.fs.normalize(vim.fn.fnamemodify(file, ":p:h")):gsub("/+$", "")
  local exec = vim.fn.fnamemodify(file, ":p:r")
  if is_win and not exec:lower():match("%.exe$") then
    exec = exec .. ".exe"
  end

  return file, dir, exec
end

function M.compile(compiler, std_ver, flag_list, file, exec, config)
  config = config or require("cprun.config").options
  local flags = table.concat(flag_list, " ")
  local compile_cmd = string.format(
    "%s -std=%s %s %s -o %s",
    compiler,
    std_ver,
    flags,
    vim.fn.shellescape(file),
    vim.fn.shellescape(exec)
  )

  local compile_out = vim.fn.system(compile_cmd)
  if vim.v.shell_error ~= 0 then
    local lines = vim.split(compile_out, "\n", { trimempty = true })
    vim.fn.setqflist({}, "r", {
      title = "cprun compilation errors",
      lines = lines,
    })
    vim.cmd("copen " .. (config.qf_height or 10))
    vim.notify("✗ Compilation failed", vim.log.levels.ERROR, { title = "cprun.nvim" })
    return false
  end

  pcall(vim.cmd, "cclose")
  return true
end

function M.execute_with_redirection(compiler, std_ver, flag_list, config)
  config = config or require("cprun.config").options
  vim.cmd("wall")

  local file, dir, exec = get_cpp_and_exec()
  if not file then
    return
  end

  local inp = vim.fs.normalize(dir .. "/" .. config.input_file)
  local out = vim.fs.normalize(dir .. "/" .. config.output_file)

  if vim.fn.filereadable(inp) == 0 then
    vim.fn.writefile({}, inp)
  end
  if vim.fn.filereadable(out) == 0 then
    vim.fn.writefile({}, out)
  end

  if not M.compile(compiler, std_ver, flag_list, file, exec, config) then
    return
  end

  local hrtime = (vim.uv and vim.uv.hrtime) or vim.loop.hrtime
  local start = hrtime()

  local run_cmd = string.format(
    "%s < %s > %s 2>&1",
    vim.fn.shellescape(exec),
    vim.fn.shellescape(inp),
    vim.fn.shellescape(out)
  )
  vim.fn.system(run_cmd)
  local exit_code = vim.v.shell_error
  local elapsed_ms = (hrtime() - start) / 1e6

  layout.refresh_buffer(out)

  local time_str = elapsed_ms < 1000
    and string.format("%dms", math.floor(elapsed_ms + 0.5))
    or string.format("%.2fs", elapsed_ms / 1000)

  if exit_code ~= 0 then
    vim.notify(
      string.format("✗ Finished in %s (exit code %d)", time_str, exit_code),
      vim.log.levels.WARN,
      { title = "cprun.nvim" }
    )
  else
    vim.notify(
      string.format("✓ Finished in %s", time_str),
      vim.log.levels.INFO,
      { title = "cprun.nvim" }
    )
  end
end

function M.run_fast(config)
  config = config or require("cprun.config").options
  vim.cmd("wall")

  local file, _, exec = get_cpp_and_exec()
  if not file then
    return
  end

  if not M.compile(config.compiler, config.cpp_std, config.fast_flags, file, exec, config) then
    return
  end

  vim.cmd("botright split")
  vim.cmd("resize " .. config.term_height)
  vim.cmd("terminal " .. vim.fn.shellescape(exec))
  vim.cmd("startinsert")
end

function M.run_warnings(config)
  M.execute_with_redirection(config.compiler, config.cpp_std, config.flags, config)
end

function M.run_asan(config)
  M.execute_with_redirection(config.asan_compiler, config.cpp_std, config.asan_flags, config)
end

return M
