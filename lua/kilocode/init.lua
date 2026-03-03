---KiloCode.nvim - Integración de KiloCode CLI con Neovim
---@author Daniel Diaz <daddydiaz2@gmail.com>
---@license MIT

local M = {}

-- Cargar configuración
local config = require("kilocode.config")

-- Estado del plugin
M.state = {
  terminal_buf = nil,
  terminal_win = nil,
  input_buf = nil,
  input_win = nil,
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
  -- Check for visual mode (v, V, or Ctrl-V/block)
  -- Note: In Neovim, Ctrl-V in visual mode returns byte value 22
  if mode == "v" or mode == "V" or mode == "\22" then
    local start_line = vim.fn.line("v")
    local end_line = vim.fn.line(".")
    -- Ensure valid line range
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
  -- Validate that we have a valid selection
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

-- Reemplazar contextos en un prompt
function M.replace_contexts(prompt)
  local ctx = Context:new()
  local result = prompt
  
  for placeholder, fn in pairs(config.opts.contexts) do
    if result:match(vim.pesc(placeholder)) then
      local ok, value = pcall(fn, ctx)
      if ok and value then
        -- Use function replacement to handle special characters in value
        result = result:gsub(vim.pesc(placeholder), function() return value end)
      end
    end
  end
  
  return result
end

-- Calcular dimensiones de ventana
local function calc_dimensions()
  local opts = config.opts.terminal
  local win_width = vim.o.columns
  local win_height = vim.o.lines
  local row, col, width, height

  if opts.position == "right" then
    row = 0
    col = win_width - opts.width
    width = opts.width
    height = win_height - 4
  elseif opts.position == "left" then
    row = 0
    col = 0
    width = opts.width
    height = win_height - 4
  elseif opts.position == "bottom" then
    row = win_height - opts.height - 4
    col = 0
    width = win_width
    height = opts.height
  elseif opts.position == "top" then
    row = 0
    col = 0
    width = win_width
    height = opts.height
  else
    -- Default to right
    row = 0
    col = win_width - 80
    width = 80
    height = win_height - 4
  end

  return row, col, width, height
end

-- Crear ventana de terminal
function M.create_terminal_window()
  if M.state.terminal_win and vim.api.nvim_win_is_valid(M.state.terminal_win) then
    vim.api.nvim_set_current_win(M.state.terminal_win)
    return
  end

  local row, col, width, height = calc_dimensions()
  local opts = config.opts.terminal

  -- Crear buffer
  M.state.terminal_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(M.state.terminal_buf, "KiloCode")

  -- Opciones de ventana
  local win_opts = {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = opts.border,
    title = " 󱐋 KiloCode ",
    title_pos = "center",
  }

  -- Crear ventana
  M.state.terminal_win = vim.api.nvim_open_win(M.state.terminal_buf, true, win_opts)

  -- Configurar terminal
  local cmd = config.opts.server.cmd
  local args = config.opts.server.args or {}
  local full_cmd = cmd
  if #args > 0 then
    full_cmd = full_cmd .. " " .. table.concat(args, " ")
  end

  vim.fn.termopen(full_cmd, {
    env = config.opts.server.env,
    on_exit = function()
      M.state.session_active = false
    end,
  })

  M.state.job_id = vim.bo[M.state.terminal_buf].channel
  M.state.session_active = true

  -- Configurar buffer
  vim.bo[M.state.terminal_buf].modifiable = false
  vim.bo[M.state.terminal_buf].filetype = "kilocode"

  -- Keymaps
  local buf_opts = { buffer = M.state.terminal_buf, noremap = true, silent = true }
  vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", buf_opts)
  vim.keymap.set("t", "<C-q>", function() M.close() end, buf_opts)
  vim.keymap.set("n", "q", function() M.close() end, buf_opts)
  vim.keymap.set("n", "<C-c>", function() M.close() end, buf_opts)

  -- Auto-scroll
  if opts.autoscroll then
    local group = vim.api.nvim_create_augroup("KiloCodeTerminal", { clear = true })
    vim.api.nvim_create_autocmd("TextChanged", {
      group = group,
      buffer = M.state.terminal_buf,
      callback = function()
        if M.state.terminal_win and vim.api.nvim_win_is_valid(M.state.terminal_win) then
          local line_count = vim.api.nvim_buf_line_count(M.state.terminal_buf)
          pcall(function()
            vim.api.nvim_win_set_cursor(M.state.terminal_win, { line_count, 0 })
          end)
        end
      end,
      desc = "Auto-scroll KiloCode terminal",
    })
  end

  vim.cmd("startinsert")
end

-- Crear ventana de input
function M.create_input_window()
  if not M.state.terminal_win or not vim.api.nvim_win_is_valid(M.state.terminal_win) then
    M.create_terminal_window()
    return
  end

  if M.state.input_win and vim.api.nvim_win_is_valid(M.state.input_win) then
    vim.api.nvim_set_current_win(M.state.input_win)
    vim.cmd("startinsert")
    return
  end

  -- Calcular posición debajo de la terminal
  local term_pos = vim.api.nvim_win_get_position(M.state.terminal_win)
  local term_width = vim.api.nvim_win_get_width(M.state.terminal_win)
  local term_height = vim.api.nvim_win_get_height(M.state.terminal_win)

  -- Crear buffer
  M.state.input_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(M.state.input_buf, "KiloCode Input")
  vim.bo[M.state.input_buf].buftype = "prompt"
  vim.bo[M.state.input_buf].filetype = "kilocode-input"

  -- Configurar prompt
  vim.fn.prompt_setprompt(M.state.input_buf, " ")

  -- Opciones de ventana
  local win_opts = {
    relative = "editor",
    row = term_pos[1] + term_height + 1,
    col = term_pos[2],
    width = term_width,
    height = 3,
    style = "minimal",
    border = "rounded",
    title = " Prompt ",
    title_pos = "center",
  }

  M.state.input_win = vim.api.nvim_open_win(M.state.input_buf, true, win_opts)

  -- Callback de prompt
  vim.fn.prompt_setcallback(M.state.input_buf, function(text)
    local ok, err = pcall(function()
      if text and text:gsub("%s", "") ~= "" then
        table.insert(M.state.history, text)
        M.state.history_index = #M.state.history + 1
        M.send(text)
      end
      -- Limpiar input
      if M.state.input_buf and vim.api.nvim_buf_is_valid(M.state.input_buf) then
        vim.api.nvim_buf_set_lines(M.state.input_buf, 0, -1, false, {})
      end
    end)
    if not ok then
      vim.notify("Error en callback: " .. tostring(err), vim.log.levels.ERROR)
    end
  end)

  -- Keymaps
  local buf_opts = { buffer = M.state.input_buf, noremap = true, silent = true }
  
  vim.keymap.set({ "i", "n" }, "<Esc>", function()
    M.close_input()
    if M.state.terminal_win and vim.api.nvim_win_is_valid(M.state.terminal_win) then
      vim.api.nvim_set_current_win(M.state.terminal_win)
    end
  end, buf_opts)

  vim.keymap.set("i", "<Tab>", function()
    vim.api.nvim_set_current_win(M.state.terminal_win)
    vim.cmd("startinsert")
  end, buf_opts)

  -- Historial
  vim.keymap.set("i", "<Up>", function()
    if M.state.history_index > 1 then
      M.state.history_index = M.state.history_index - 1
      local text = M.state.history[M.state.history_index] or ""
      vim.api.nvim_buf_set_lines(M.state.input_buf, 0, -1, false, { text })
      vim.api.nvim_win_set_cursor(M.state.input_win, { 1, #text })
    end
  end, buf_opts)

  vim.keymap.set("i", "<Down>", function()
    if M.state.history_index < #M.state.history then
      M.state.history_index = M.state.history_index + 1
      local text = M.state.history[M.state.history_index] or ""
      vim.api.nvim_buf_set_lines(M.state.input_buf, 0, -1, false, { text })
      vim.api.nvim_win_set_cursor(M.state.input_win, { 1, #text })
    else
      M.state.history_index = #M.state.history + 1
      vim.api.nvim_buf_set_lines(M.state.input_buf, 0, -1, false, {})
    end
  end, buf_opts)

  vim.cmd("startinsert")
end

-- Enviar mensaje a KiloCode
function M.send(text)
  if not M.state.terminal_buf or not vim.api.nvim_buf_is_valid(M.state.terminal_buf) then
    vim.notify("KiloCode no está activo", vim.log.levels.ERROR)
    return
  end

  -- Validar job_id
  if not M.state.job_id or M.state.job_id == 0 then
    vim.notify("Terminal de KiloCode no está lista", vim.log.levels.ERROR)
    return
  end

  -- Procesar contextos
  local processed = M.replace_contexts(text)

  -- Enviar a terminal
  local ok, err = pcall(vim.fn.chansend, M.state.job_id, processed .. "\n")
  if not ok then
    vim.notify("Error al enviar mensaje: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  -- Volver a terminal
  if M.state.terminal_win and vim.api.nvim_win_is_valid(M.state.terminal_win) then
    vim.api.nvim_set_current_win(M.state.terminal_win)
    vim.cmd("startinsert")
  end
end

-- Cerrar input
function M.close_input()
  if M.state.input_win and vim.api.nvim_win_is_valid(M.state.input_win) then
    vim.api.nvim_win_close(M.state.input_win, true)
    M.state.input_win = nil
    M.state.input_buf = nil
  end
end

-- Cerrar todo
function M.close()
  M.close_input()
  if M.state.terminal_win and vim.api.nvim_win_is_valid(M.state.terminal_win) then
    vim.api.nvim_win_close(M.state.terminal_win, true)
  end
  M.state.terminal_win = nil
  M.state.terminal_buf = nil
  M.state.job_id = nil
  M.state.session_active = false
end

-- Toggle
function M.toggle()
  if M.state.terminal_win and vim.api.nvim_win_is_valid(M.state.terminal_win) then
    M.close()
  else
    M.create_terminal_window()
  end
end

-- Ask
function M.ask(prompt, opts)
  opts = opts or {}
  prompt = prompt or ""

  if not M.state.terminal_win or not vim.api.nvim_win_is_valid(M.state.terminal_win) then
    M.create_terminal_window()
  end

  if opts.submit and prompt ~= "" then
    M.send(prompt)
  else
    M.create_input_window()
    if prompt ~= "" then
      -- Establecer texto inicial
      vim.defer_fn(function()
        if M.state.input_buf and vim.api.nvim_buf_is_valid(M.state.input_buf) then
          vim.api.nvim_buf_set_lines(M.state.input_buf, 0, -1, false, { prompt })
          if M.state.input_win and vim.api.nvim_win_is_valid(M.state.input_win) then
            pcall(function()
              vim.api.nvim_win_set_cursor(M.state.input_win, { 1, #prompt })
            end)
          end
        end
      end, 50)
    end
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
      table.insert(items, { name = name, prompt = p })
    end
  end

  table.sort(items, function(a, b) return a.name < b.name end)

  vim.ui.select(items, {
    prompt = config.opts.select.prompt,
    format_item = function(item)
      return string.format("%s: %s", item.name, item.prompt.prompt:sub(1, 50))
    end,
  }, function(choice)
    if choice then
      M.prompt(choice.name)
    end
  end)
end

-- Operador
function M.operator(type)
  -- If called without type (from g@), we need to set up the operator
  if not type then
    vim.o.operatorfunc = "v:lua.require'kilocode'.operator"
    return "g@"
  end
  
  -- Get the selected text
  local selection = vim.fn.getreg('v')
  if selection == "" then
    -- Fallback: try to get from unnamed register
    selection = vim.fn.getreg('"')
  end
  
  M.ask("", { submit = false })
  
  vim.defer_fn(function()
    if M.state.input_buf and vim.api.nvim_buf_is_valid(M.state.input_buf) then
      local text = "@selection: " .. selection:gsub("\n", " "):sub(1, 100)
      vim.api.nvim_buf_set_lines(M.state.input_buf, 0, -1, false, { text })
      if M.state.input_win and vim.api.nvim_win_is_valid(M.state.input_win) then
        pcall(function()
          vim.api.nvim_win_set_cursor(M.state.input_win, { 1, #text })
        end)
      end
    end
  end, 100)
  
  return ""
end

-- Comando
function M.command(cmd)
  if cmd == "new" then
    M.close()
    vim.defer_fn(M.create_terminal_window, 100)
  elseif cmd == "close" then
    M.close()
  elseif cmd == "toggle" then
    M.toggle()
  else
    vim.notify("Comando no reconocido: " .. cmd, vim.log.levels.ERROR)
  end
end

-- Statusline
function M.statusline()
  return M.state.session_active and "󱐋 KiloCode" or ""
end

-- Setup
function M.setup(opts)
  if opts then
    vim.g.kilocode_opts = vim.tbl_deep_extend("force", vim.g.kilocode_opts or {}, opts)
  end
  require("kilocode.config") -- Recargar configuración
end

return M
