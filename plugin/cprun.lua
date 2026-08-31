if vim.g.loaded_cprun == 1 then
  return
end
vim.g.loaded_cprun = 1

vim.api.nvim_create_user_command("CPToggle", function()
  require("cprun").toggle_layout()
end, { desc = "Toggle Competitive Programming layout (inp / out splits)" })

vim.api.nvim_create_user_command("CPRunFast", function()
  require("cprun").run_fast()
end, { desc = "Fast compile C++ and open interactive terminal run" })

vim.api.nvim_create_user_command("CPRunWarnings", function()
  require("cprun").run_warnings()
end, { desc = "Compile C++ with warnings and run with input/output redirection" })

vim.api.nvim_create_user_command("CPRunAsan", function()
  require("cprun").run_asan()
end, { desc = "Compile C++ with AddressSanitizer and run with input/output redirection" })

