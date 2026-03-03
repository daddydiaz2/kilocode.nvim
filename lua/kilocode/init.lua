---KiloCode.nvim - Integración de KiloCode CLI con Neovim (modo opencode-style)
---@author Daniel Diaz <daddydiaz2@gmail.com>
---@license MIT

local M = {}

-- Cargar configuración
local config = require("kilocode.config")

-- Estado del plugin
M.state = {
  buf = nil,
  win = nil,
  job_id = nil,
  session_active = false,
  history = {},
  history_index = 0,
}

---@class kilocode.Context
local Context = {}
Context.__index = Context

function Context:new()
  return setmetatable({}, self)
end

function Context:this()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    local start_line = vim.fn.line("v")
    local end_line = vim.fn.line(".")
    if start_line > end_line then
      start_line, end_line = end_line, start_line
    end
    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
    return table.concat(lines, "\n")
  else
    return vim.api.nvim_get_current_line()
  end
end

function Context:buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  return table.concat(lines, "\n")
end

function Context:selection()
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  if start_line == 0 or end_line == 0 or start_line > end_line then
    return ""
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
  return table.concat(lines, "\n")
end

function Context:filename()
  return vim.fn.expand("%:t")
end

function Context:filepath()
  return vim.fn.expand("%:p")
end

function Context:file_content()
  local filepath = vim.fn.expand("%:p")
  local content = self:buffer()
  return string.format("File: %s\n```\n%s\n```", filepath, content)
end

function Context:diagnostics()
  local bufnr = vim.api.nvim_get_current_buf()
  local diagnostics = vim.diagnostic.get(bufnr)
  if #diagnostics == 0 then
    return "No hay diagnósticos"
  end
  local lines = {}
  for _, d in ipairs(diagnostics) do
    local severity = vim.diagnostic.severity[d.severity] or "UNKNOWN"
    table.insert(lines, string.format("[%s] Línea %d: %s", severity, d.lnum + 1, d.message))
  end
  return table.concat(lines, "\n")
end

-- Reemplazar contextos
function M.replace_contexts(prompt)
  local ctx = Context:new()
  local result = prompt
  
  for placeholder, fn in pairs(config.opts.contexts) do
    if result:match(vim.pesc(placeholder)) then
      local ok, value = pcall(fn, ctx)
      if ok and value then
        result = result:gsub(vim.pesc(placeholder), function() return value end)
      end
    end
  end
  
  return result
end

-- Abrir KiloCode en split (como opencode.nvim)
function M.open()
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    vim.api.nvim_set_current_win(M.state.win)
    return
  end

  local split_cmd = config.opts.split or "vsplit"
  vim.cmd(split_cmd)
  
  M.state.win = vim.api.nvim_get_current_win()
  
  -- Crear o reutilizar buffer
  if not M.state.buf or not vim.api.nvim_buf_is_valid(M.state.buf) then
    M.state.buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(M.state.buf, "KiloCode")
  end
  
  vim.api.nvim_win_set_buf(M.state.win, M.state.buf)
  
  -- Configurar terminal
  local cmd = config.opts.server.cmd
  local args = config.opts.server.args or {}
  if #args > 0 then
    cmd = cmd .. " " .. table.concat(args, " ")
  end
  
  vim.fn.termopen(cmd, {
    env = config.opts.server.env,
    on_exit = function()
      M.state.session_active = false
    end,
  })
  
  M.state.job_id = vim.bo[M.state.buf].channel
  M.state.session_active = true
  
  -- Configurar buffer
  vim.bo[M.state.buf].modifiable = false
  vim.bo[M.state.buf].filetype = "kilocode"
  
  -- Keymaps específicas del buffer
  local buf_opts = { buffer = M.state.buf, noremap = true, silent = true }
  vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", buf_opts)
  vim.keymap.set("n", "q", function() M.close() end, buf_opts)
  vim.keymap.set("n", "<C-c>", function() M.close() end, buf_opts)
  
  -- Auto-scroll
  if config.opts.autoscroll ~= false then
    local group = vim.api.nvim_create_augroup("KiloCodeScroll", { clear = true })
    vim.api.nvim_create_autocmd("TextChanged", {
      group = group,
      buffer = M.state.buf,
      callback = function()
        if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
          local line_count = vim.api.nvim_buf_line_count(M.state.buf)
          pcall(function()
            vim.api.nvim_win_set_cursor(M.state.win, { line_count, 0 })
          end)
        end
      end,
    })
  end
  
  vim.cmd("startinsert")
end

-- Cerrar KiloCode
function M.close()
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    vim.api.nvim_win_close(M.state.win, true)
  end
  M.state.win = nil
  M.state.job_id = nil
  M.state.session_active = false
end

-- Toggle (abrir/cerrar)
function M.toggle()
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    M.close()
  else
    M.open()
  end
end

-- Enviar mensaje a KiloCode
function M.send(text)
  if not M.state.buf or not vim.api.nvim_buf_is_valid(M.state.buf) then
    vim.notify("KiloCode no está abierto. Usa :Kilo o <C-.> para abrirlo", vim.log.levels.WARN)
    return
  end
  
  if not M.state.job_id or M.state.job_id == 0 then
    vim.notify("Terminal de KiloCode no está lista", vim.log.levels.ERROR)
    return
  end
  
  local processed = M.replace_contexts(text)
  
  local ok, err = pcall(vim.fn.chansend, M.state.job_id, processed .. "\n")
  if not ok then
    vim.notify("Error al enviar: " .. tostring(err), vim.log.levels.ERROR)
    return
  end
  
  -- Volver a la ventana de KiloCode
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    vim.api.nvim_set_current_win(M.state.win)
    vim.cmd("startinsert")
  end
end

-- Ask - abrir input y enviar
function M.ask(prompt, opts)
  opts = opts or {}
  prompt = prompt or ""
  
  if not M.state.win or not vim.api.nvim_win_is_valid(M.state.win) then
    M.open()
  end
  
  if opts.submit and prompt ~= "" then
    vim.defer_fn(function()
      M.send(prompt)
    end, 100)
  else
    -- Abrir input con vim.ui.input
    vim.ui.input({
      prompt = "KiloCode: ",
      default = prompt,
    }, function(input)
      if input and input:gsub("%s", "") ~= "" then
        table.insert(M.state.history, input)
        M.state.history_index = #M.state.history + 1
        M.send(input)
      end
    end)
  end
end

-- Prompt predefinido
function M.prompt(name)
  local p = config.opts.prompts[name]
  if not p then
    vim.notify("Prompt no encontrado: " .. name, vim.log.levels.ERROR)
    return
  end
  M.ask(p.prompt, { submit = p.submit })
end

-- Seleccionar prompt
function M.select()
  local items = {}
  for name, p in pairs(config.opts.prompts) do
    if name ~= "ask" then
      table.insert(items, { name = name, prompt = p.prompt })
    end
  end
  
  table.sort(items, function(a, b) return a.name < b.name end)
  
  vim.ui.select(items, {
    prompt = "KiloCode: ",
    format_item = function(item)
      return string.format("%s: %s", item.name, item.prompt:sub(1, 50))
    end,
  }, function(choice)
    if choice then
      M.prompt(choice.name)
    end
  end)
end

-- Operador (para usar con go, goo)
function M.operator(type)
  if not type then
    vim.o.operatorfunc = "v:lua.require'kilocode'.operator"
    return "g@"
  end
  
  local selection = vim.fn.getreg('v')
  if selection == "" then
    selection = vim.fn.getreg('"')
  end
  
  M.ask("", { submit = false })
  
  vim.defer_fn(function()
    local text = "@selection: " .. selection:gsub("\n", " "):sub(1, 100)
    M.send(text)
  end, 100)
  
  return ""
end

-- Comando
function M.command(cmd)
  if cmd == "new" then
    M.close()
    vim.defer_fn(M.open, 100)
  elseif cmd == "close" then
    M.close()
  elseif cmd == "toggle" then
    M.toggle()
  elseif cmd == "open" then
    M.open()
  else
    vim.notify("Comando: " .. cmd, vim.log.levels.INFO)
  end
end

-- Statusline
function M.statusline()
  return M.state.session_active and "󱐋 Kilo" or ""
end

-- Setup
function M.setup(opts)
  if opts then
    vim.g.kilocode_opts = vim.tbl_deep_extend("force", vim.g.kilocode_opts or {}, opts)
    require("kilocode.config")
  end
  
  -- Crear comandos de usuario
  vim.api.nvim_create_user_command("Kilo", function()
    M.toggle()
  end, { desc = "Toggle KiloCode panel" })
  
  vim.api.nvim_create_user_command("KiloOpen", function()
    M.open()
  end, { desc = "Open KiloCode panel" })
  
  vim.api.nvim_create_user_command("KiloClose", function()
    M.close()
  end, { desc = "Close KiloCode panel" })
  
  vim.api.nvim_create_user_command("KiloAsk", function(opts)
    M.ask(opts.args, { submit = opts.bang })
  end, { nargs = "?", bang = true, desc = "Ask KiloCode" })
  
  vim.api.nvim_create_user_command("KiloPrompt", function(opts)
    M.prompt(opts.args)
  end, { nargs = 1, complete = function()
    local ok, conf = pcall(require, "kilocode.config")
    if ok then
      return vim.tbl_keys(conf.opts.prompts or {})
    end
    return {}
  end, desc = "Execute KiloCode prompt" })
  
  vim.api.nvim_create_user_command("KiloSelect", function()
    M.select()
  end, { desc = "Select KiloCode prompt" })
end

return M
