local config = require("cprun.config")
local layout = require("cprun.layout")
local run = require("cprun.run")

local M = {}

M.config = config.options

function M.pre_run()
  run.pre_run()
end

function M.toggle_layout()
  layout.toggle_layout(config.options)
end

function M.run_fast()
  run.run_fast(config.options)
end

function M.run_warnings()
  run.run_warnings(config.options)
end

function M.run_asan()
  run.run_asan(config.options)
end

-- setup: merge options, register auto-save and buffer-local cpp keymaps
function M.setup(opts)
  local cfg = config.setup(opts)
  M.config = cfg

  if cfg.auto_save then
    local group = vim.api.nvim_create_augroup("cprun_autosave", { clear = true })
    vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
      group = group,
      pattern = { cfg.input_file, cfg.output_file },
      callback = function()
        if vim.bo.modified then
          vim.cmd("silent write")
        end
      end,
    })
  end

  if cfg.keymaps.enable then
    local group = vim.api.nvim_create_augroup("cprun_keymaps", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = "cpp",
      callback = function(ev)
        local km = cfg.keymaps
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
