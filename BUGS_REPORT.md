# Reporte de Debugging - kilocode.nvim

Fecha: 2026-03-03
Autor: Análisis Automático

## 🐛 BUGS ENCONTRADOS

### 1. CRÍTICO: Modo visual block mal detectado (init.lua:32)
**Problema:** `\22` puede no detectarse correctamente en todas las versiones de Neovim.
**Impacto:** El contexto @this no funciona en modo visual bloque.

### 2. CRÍTICO: Comando con espacio final (init.lua:174)
**Problema:** Si args está vacío, se genera `"kilo "` en lugar de `"kilo"`.
**Impacto:** Algunos shells pueden no encontrar el comando.

### 3. CRÍTICO: Obtención incorrecta de job_id (init.lua:183)
**Problema:** `vim.bo[buf].channel` no es la forma correcta de obtener el job de terminal.
**Impacto:** El envío de mensajes puede fallar.

### 4. CRÍTICO: Función operator no retorna valor (init.lua:415)
**Problema:** Se usa con `expr = true` pero no devuelve nada.
**Impacto:** Los keymaps con `go` y `goo` no funcionan correctamente.

### 5. ALTO: Manejo de errores en replace_contexts (init.lua:95-96)
**Problema:** Si `value` contiene `%`, gsub lo interpreta como patrón.
**Impacto:** Reemplazo incorrecto de contextos.

### 6. ALTO: No se valida job_id antes de chansend (init.lua:317)
**Problema:** `M.state.job_id` podría ser nil.
**Impacto:** Error Lua si se llama send() antes de que la terminal esté lista.

### 7. ALTO: Autocmd sin grupo ni desc (init.lua:199-209)
**Problema:** Sin grupo, los autocmds se duplican al recrear la terminal.
**Impacto:** Fuga de memoria y múltiples callbacks ejecutándose.

### 8. MEDIO: No validación de ventana input (init.lua:373-374)
**Problema:** Se accede a `M.state.input_win` sin verificar si es válido.
**Impacto:** Error Lua si la ventana se cierra rápidamente.

### 9. MEDIO: Context:this puede fallar sin selección (init.lua:48-55)
**Problema:** Si no hay selección previa, `line("'<")` devuelve 0.
**Impacto:** Contexto @selection devuelve texto incorrecto.

### 10. MEDIO: Callback de prompt sin pcall (init.lua:258-266)
**Problema:** Si M.send() falla, el callback no maneja el error.
**Impacto:** Estado inconsistente del input.

### 11. BAJO: Icono en prompt puede no renderizar (init.lua:240)
**Problema:** El carácter "" puede no mostrarse en terminales sin soporte Unicode.
**Impacto:** Visual solamente.

### 12. BAJO: Configuración no reactiva (config.lua:96)
**Problema:** Los cambios a `vim.g.kilocode_opts` después del require no se aplican.
**Impacto:** Usuario debe reiniciar Neovim para cambiar config.

### 13. BAJO: Historial no persiste entre sesiones
**Problema:** El historial se guarda en memoria pero no en disco.
**Impacto:** Se pierde al cerrar Neovim.

## ✅ CORRECCIONES NECESARIAS

### init.lua - Línea 32: Detección de modo visual
```lua
-- ANTES:
if mode == "v" or mode == "V" or mode == "\22" then

-- DESPUÉS:
if mode == "v" or mode == "V" or mode == "\22" or mode:byte() == 22 then
```

### init.lua - Línea 172-174: Construcción de comando
```lua
-- ANTES:
local cmd = config.opts.server.cmd
local args = config.opts.server.args or {}
local full_cmd = cmd .. " " .. table.concat(args, " ")

-- DESPUÉS:
local cmd = config.opts.server.cmd
local args = config.opts.server.args or {}
local full_cmd = cmd
if #args > 0 then
  full_cmd = full_cmd .. " " .. table.concat(args, " ")
end
```

### init.lua - Línea 183: Obtención de job_id
```lua
-- ANTES:
M.state.job_id = vim.bo[M.state.terminal_buf].channel

-- DESPUÉS:
-- El job_id se obtiene automáticamente de termopen
M.state.job_id = vim.bo[M.state.terminal_buf].channel
-- Alternativa más segura: guardar el job al crear la terminal
```

### init.lua - Línea 199-209: Autocmd con grupo
```lua
-- ANTES:
vim.api.nvim_create_autocmd("TextChanged", {
  buffer = M.state.terminal_buf,
  callback = function() ... end,
})

-- DESPUÉS:
local group = vim.api.nvim_create_augroup("KiloCodeTerminal", { clear = true })
vim.api.nvim_create_autocmd("TextChanged", {
  group = group,
  buffer = M.state.terminal_buf,
  callback = function() ... end,
  desc = "Auto-scroll KiloCode terminal",
})
```

### init.lua - Línea 95-96: Escape de gsub
```lua
-- ANTES:
result = result:gsub(vim.pesc(placeholder), value)

-- DESPUÉS:
result = result:gsub(vim.pesc(placeholder), function() return value end)
```

### init.lua - Línea 415-428: Función operator
```lua
-- ANTES:
function M.operator(type)
  vim.cmd('normal! "vy')
  ...
end

-- DESPUÉS:
function M.operator(type)
  if type then
    vim.cmd('normal! "vy')
    ...
  end
  return "g@"  -- Necesario para operadores
end
```

## 🧪 TESTS RECOMENDADOS

1. Probar en Neovim 0.9, 0.10 y nightly
2. Probar con diferentes shells (bash, zsh, fish)
3. Probar con y sin selección visual
4. Probar modo visual bloque (Ctrl+V)
5. Probar cierre rápido de ventanas
6. Probar sin KiloCode CLI instalado
7. Probar con prompts largos (>1000 caracteres)
8. Probar con caracteres especiales en código

## 📊 SEVERIDAD

- 🔴 CRÍTICO: 4 bugs (causan errores o crashes)
- 🟠 ALTO: 3 bugs (funcionalidad comprometida)
- 🟡 MEDIO: 2 bugs (problemas esquina)
- 🟢 BAJO: 4 bugs (menores/mejoras)

## 🎯 PRIORIDAD DE ARREGLO

1. Bug #4 (operator sin return) - Rompe keymaps principales
2. Bug #3 (job_id incorrecto) - Rompe envío de mensajes
3. Bug #6 (chansend sin validar) - Puede crashear
4. Bug #1 (modo visual block) - Afecta funcionalidad core
5. Bug #7 (autocmd sin grupo) - Fuga de memoria
