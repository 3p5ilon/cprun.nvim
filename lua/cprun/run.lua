local layout = require("cprun.layout")

local M = {}

function M.pre_run()
  vim.cmd("wall")
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
    local qf_h = config.qf_height or 10
    vim.cmd("copen " .. qf_h)
    vim.notify("✗ Compilation failed", vim.log.levels.ERROR, { title = "cprun.nvim" })
    return false
  end

  pcall(vim.cmd, "cclose")
  return true
end

function M.execute_with_redirection(compiler, std_ver, flag_list, config)
  config = config or require("cprun.config").options
  M.pre_run()

  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("No valid C++ file to compile", vim.log.levels.ERROR, { title = "cprun.nvim" })
    return
  end

  local dir = vim.fn.fnamemodify(file, ":p:h"):gsub("/+$", "")
  local exec = vim.fn.fnamemodify(file, ":p:r")

  local inp_path = dir .. "/" .. config.input_file
  local out_path = dir .. "/" .. config.output_file

  if vim.fn.filereadable(inp_path) == 0 then
    vim.fn.writefile({}, inp_path)
  end
  if vim.fn.filereadable(out_path) == 0 then
    vim.fn.writefile({}, out_path)
  end

  if not M.compile(compiler, std_ver, flag_list, file, exec, config) then
    return
  end

  local hrtime = (vim.uv and vim.uv.hrtime) or vim.loop.hrtime
  local start_time = hrtime()

  local run_cmd = string.format(
    "%s < %s > %s 2>&1",
    vim.fn.shellescape(exec),
    vim.fn.shellescape(inp_path),
    vim.fn.shellescape(out_path)
  )
  vim.fn.system(run_cmd)
  local exit_code = vim.v.shell_error

  local elapsed_ms = (hrtime() - start_time) / 1e6

  layout.refresh_buffer(out_path)

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
  M.pre_run()

  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("No valid C++ file to compile", vim.log.levels.ERROR, { title = "cprun.nvim" })
    return
  end

  local exec = vim.fn.fnamemodify(file, ":p:r")

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

