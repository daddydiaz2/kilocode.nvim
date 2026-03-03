local M = {}

---Your `kilocode.nvim` configuration.
---Passed via global variable for simpler UX and faster startup.
---@type kilocode.Opts|nil
vim.g.kilocode_opts = vim.g.kilocode_opts

---@class kilocode.Opts
---
---Configuration for the KiloCode CLI integration.
---@field server? kilocode.server.Opts
---
---Contexts to inject into prompts, keyed by their placeholder.
---@field contexts? table<string, fun(context: kilocode.Context): string|nil>
---
---Prompts to reference or select from.
---@field prompts? table<string, kilocode.Prompt>
---
---Options for `ask()`.
---@field ask? kilocode.ask.Opts
---
---Options for `select()`.
---@field select? kilocode.select.Opts
---
---Options for the terminal window.
---@field terminal? kilocode.terminal.Opts

---@class kilocode.Prompt
---@field prompt string The prompt to send to KiloCode.
---@field submit? boolean Submit immediately without showing input.

---@class kilocode.server.Opts
---@field cmd? string Command to run KiloCode CLI (default: "kilo")
---@field args? string[] Additional arguments
---@field env? table<string, string> Environment variables

---@class kilocode.terminal.Opts
---@field position? "right"|"left"|"bottom"|"top" Window position
---@field width? number Window width (for left/right)
---@field height? number Window height (for top/bottom)
---@field border? "none"|"single"|"double"|"rounded"|"solid"|"shadow" Border style
---@field autoscroll? boolean Auto-scroll to bottom

---@class kilocode.ask.Opts
---@field prompt? string Input prompt text
---@field submit? boolean Submit immediately

---@class kilocode.select.Opts
---@field prompt? string Selection prompt text

---@type kilocode.Opts
local defaults = {
  server = {
    cmd = "kilo",
    args = {},
    env = {},
  },
  terminal = {
    position = "right",
    width = 80,
    height = 20,
    border = "rounded",
    autoscroll = true,
  },
  -- stylua: ignore
  contexts = {
    ["@this"] = function(ctx) return ctx:this() end,
    ["@buffer"] = function(ctx) return ctx:buffer() end,
    ["@selection"] = function(ctx) return ctx:selection() end,
    ["@filename"] = function(ctx) return ctx:filename() end,
    ["@filepath"] = function(ctx) return ctx:filepath() end,
    ["@diagnostics"] = function(ctx) return ctx:diagnostics() end,
    ["@file"] = function(ctx) return ctx:file_content() end,
  },
  prompts = {
    ask = { prompt = "", submit = false },
    explain = { prompt = "Explica @this y su contexto", submit = true },
    review = { prompt = "Revisa @this para verificar corrección y legibilidad", submit = true },
    fix = { prompt = "Corrige los errores en @this. Diagnósticos: @diagnostics", submit = true },
    document = { prompt = "Agrega comentarios documentando @this", submit = true },
    test = { prompt = "Genera tests para @this", submit = true },
    optimize = { prompt = "Optimiza @this para rendimiento y legibilidad", submit = true },
    refactor = { prompt = "Refactoriza @this siguiendo las mejores prácticas", submit = true },
    implement = { prompt = "Implementa la funcionalidad descrita en @this", submit = true },
  },
  ask = {
    prompt = "KiloCode: ",
  },
  select = {
    prompt = "KiloCode: ",
  },
}

---Plugin options, lazily merged from `defaults` and `vim.g.kilocode_opts`.
---@type kilocode.Opts
M.opts = vim.tbl_deep_extend("force", vim.deepcopy(defaults), vim.g.kilocode_opts or {})

-- Allow removing default `contexts` and `prompts` by setting them to `false` in user config.
local user_opts = vim.g.kilocode_opts or {}
for _, field in ipairs({ "contexts", "prompts" }) do
  if user_opts[field] and M.opts[field] then
    for k, v in pairs(user_opts[field]) do
      if not v then
        M.opts[field][k] = nil
      end
    end
  end
end

return M
