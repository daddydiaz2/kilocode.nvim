-- kilocode.nvim - Integración de KiloCode CLI con Neovim (modo opencode-style)
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

-- Auto-setup al cargar el plugin
-- Los comandos y keymaps se configuran en setup()
-- NO se abre automáticamente - el usuario controla con :Kilo o <C-.>
vim.defer_fn(function()
  require("kilocode").setup()
end, 0)

-- Health check command (adicional)
vim.api.nvim_create_user_command("KiloHealth", function()
  vim.cmd("checkhealth kilocode")
end, { desc = "Check KiloCode health" })

-- Highlight groups
vim.api.nvim_set_hl(0, "KiloCodeBorder", { link = "FloatBorder" })
vim.api.nvim_set_hl(0, "KiloCodeTitle", { link = "Title" })
