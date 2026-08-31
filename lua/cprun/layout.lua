local M = {}

local function get_dir_and_paths(config)
  config = config or require("cprun.config").options
  local current_buf = vim.api.nvim_get_current_buf()
  local current_path = vim.api.nvim_buf_get_name(current_buf)
  local dir = (current_path ~= "") and vim.fn.fnamemodify(current_path, ":p:h") or vim.fn.getcwd()
  dir = dir:gsub("/+$", "")

  return dir, dir .. "/" .. config.input_file, dir .. "/" .. config.output_file
end

function M.refresh_buffer(target_path)
  local bufnr = vim.fn.bufnr(target_path)
  if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd("silent checktime")
      vim.cmd("silent edit!")
    end)
  end
end

function M.toggle_layout(config)
  config = config or require("cprun.config").options
  local dir, inp_path, out_path = get_dir_and_paths(config)
  local inp_win, out_win

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      local name = vim.api.nvim_buf_get_name(buf)

      if name == inp_path then
        inp_win = win
      elseif name == out_path then
        out_win = win
      end
    end
  end

  -- Close both panes if already open (toggle)
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
    if vim.fn.filereadable(inp_path) == 0 then
      vim.fn.writefile({}, inp_path)
    end
    if vim.fn.filereadable(out_path) == 0 then
      vim.fn.writefile({}, out_path)
    end
  else
    if vim.fn.filereadable(inp_path) == 0 then
      vim.notify(config.input_file .. " file not found in " .. dir, vim.log.levels.ERROR, { title = "cprun.nvim" })
      return
    end
    if vim.fn.filereadable(out_path) == 0 then
      vim.notify(config.output_file .. " file not found in " .. dir, vim.log.levels.ERROR, { title = "cprun.nvim" })
      return
    end
  end

  local code_win = vim.api.nvim_get_current_win()

  vim.cmd("vsplit " .. vim.fn.fnameescape(inp_path))
  vim.cmd("vertical resize " .. math.floor(vim.o.columns * config.layout_width))
  vim.cmd("split " .. vim.fn.fnameescape(out_path))

  if vim.api.nvim_win_is_valid(code_win) then
    vim.api.nvim_set_current_win(code_win)
  end
end

return M

