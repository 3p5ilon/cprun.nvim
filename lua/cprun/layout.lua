local M = {}

function M.refresh_buffer(file_name)
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

function M.toggle_layout(config)
  local inp_name = config.input_file
  local out_name = config.output_file
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

  -- close both panes if already open (true toggle)
  if inp_win or out_win then
    if inp_win and vim.api.nvim_win_is_valid(inp_win) then
      vim.api.nvim_win_close(inp_win, true)
    end
    if out_win and vim.api.nvim_win_is_valid(out_win) then
      vim.api.nvim_win_close(out_win, true)
    end
    return
  end

  if config.auto_create_files then
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
  vim.cmd("vertical resize " .. math.floor(vim.o.columns * config.layout_width))
  vim.cmd("split " .. vim.fn.fnameescape(out_name))

  if vim.api.nvim_win_is_valid(code_win) then
    vim.api.nvim_set_current_win(code_win)
  end
end

return M
