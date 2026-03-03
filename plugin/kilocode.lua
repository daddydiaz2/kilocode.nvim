-- kilocode.nvim - Integración de KiloCode CLI con Neovim
-- Autor: Daniel Diaz <daddydiaz2@gmail.com>
-- Licencia: MIT
-- URL: https://github.com/daddydiaz2/kilocode.nvim

if vim.g.loaded_kilocode then
  return
end
vim.g.loaded_kilocode = true

-- Verificar versión de Neovim
if vim.fn.has("nvim-0.9") == 0 then
  vim.notify("kilocode.nvim requires Neovim >= 0.9.0", vim.log.levels.ERROR)
  return
end

-- Comandos
vim.api.nvim_create_user_command("Kilo", function()
  require("kilocode").toggle()
end, { desc = "Toggle KiloCode terminal" })

vim.api.nvim_create_user_command("KiloAsk", function(opts)
  require("kilocode").ask(opts.args, { submit = opts.bang })
end, { nargs = "?", bang = true, desc = "Ask KiloCode" })

vim.api.nvim_create_user_command("KiloPrompt", function(opts)
  require("kilocode").prompt(opts.args)
end, { nargs = 1, complete = function()
  local ok, config = pcall(require, "kilocode.config")
  if ok then
    return vim.tbl_keys(config.opts.prompts or {})
  end
  return {}
end, desc = "Execute KiloCode prompt" })

vim.api.nvim_create_user_command("KiloSelect", function()
  require("kilocode").select()
end, { desc = "Select KiloCode prompt" })

vim.api.nvim_create_user_command("KiloClose", function()
  require("kilocode").close()
end, { desc = "Close KiloCode" })

vim.api.nvim_create_user_command("KiloNew", function()
  require("kilocode").command("new")
end, { desc = "New KiloCode session" })

-- Health check command
vim.api.nvim_create_user_command("KiloHealth", function()
  vim.cmd("checkhealth kilocode")
end, { desc = "Check KiloCode health" })

-- Highlight groups
vim.api.nvim_set_hl(0, "KiloCodeBorder", { link = "FloatBorder" })
vim.api.nvim_set_hl(0, "KiloCodeTitle", { link = "Title" })
vim.api.nvim_set_hl(0, "KiloCodePrompt", { link = "Question" })
