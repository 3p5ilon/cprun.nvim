local layout = require("cprun.layout")

local M = {}

function M.pre_run()
  vim.cmd("wall")
  vim.cmd("lcd %:p:h")
end

function M.compile(compiler, std_ver, flag_list, file, exec)
  local flags = table.concat(flag_list, " ")
  local compile_cmd = string.format("%s -std=%s %s %s -o %s", compiler, std_ver, flags, vim.fn.shellescape(file), vim.fn.shellescape(exec))

  local compile_out = vim.fn.system(compile_cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("Compilation Error:\n" .. compile_out, vim.log.levels.ERROR, { title = "cprun.nvim" })
    return false
  end
  return true
end

function M.execute_with_redirection(compiler, std_ver, flag_list, config)
  M.pre_run()

  local file = vim.fn.expand("%:p")
  local exec = vim.fn.expand("%:p:r")

  if file == "" then
    vim.notify("No valid C++ file to compile", vim.log.levels.ERROR, { title = "cprun.nvim" })
    return
  end

  local inp = config.input_file
  local out = config.output_file

  if vim.fn.filereadable(inp) == 0 then
    vim.fn.writefile({}, inp)
  end
  if vim.fn.filereadable(out) == 0 then
    vim.fn.writefile({}, out)
  end

  if not M.compile(compiler, std_ver, flag_list, file, exec) then
    return
  end

  local hrtime = (vim.uv and vim.uv.hrtime) or vim.loop.hrtime
  local start_time = hrtime()

  local run_cmd = string.format("%s < %s > %s 2>&1", vim.fn.shellescape(exec), vim.fn.shellescape(inp), vim.fn.shellescape(out))
  vim.fn.system(run_cmd)
  local exit_code = vim.v.shell_error

  local elapsed_ms = (hrtime() - start_time) / 1e6

  layout.refresh_buffer(out)

  -- format as ms or seconds depending on duration
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

function M.run_fast(config)
  M.pre_run()

  local file = vim.fn.expand("%:p")
  local exec = vim.fn.expand("%:p:r")

  if file == "" then
    vim.notify("No valid C++ file to compile", vim.log.levels.ERROR, { title = "cprun.nvim" })
    return
  end

  if not M.compile(config.compiler, config.cpp_std, config.fast_flags, file, exec) then
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
