# kilocode.nvim

Integra [KiloCode CLI](https://kilo.ai) con Neovim — **como opencode.nvim pero para KiloCode**.

![KiloCode.nvim](https://img.shields.io/badge/KiloCode-CLI-blue)
![Neovim](https://img.shields.io/badge/Neovim-%205.0+-green?logo=neovim)
![Lua](https://img.shields.io/badge/Made%20with-Lua-blueviolet?logo=lua)
![License](https://img.shields.io/badge/License-MIT-yellow)

> **Funciona como [opencode.nvim](https://github.com/nickjvandyke/opencode.nvim)** — se abre **manualmente** con teclas, en un **split al costado**, integrado con tus archivos.

## ✨ Características

- 🎯 **NO se abre automáticamente** — Tú controlas cuándo abrirlo con `<C-.>`
- 🖥️ **Split al costado** — `vsplit` (derecha) o `split` (abajo), como opencode.nvim
- 📝 **Contextos inteligentes** — `@this`, `@buffer`, `@selection`, `@filename`, etc.
- 💬 **Input integrado** — Con historial (↑↓)
- 🚀 **Prompts predefinidos** — explain, review, fix, document, test, optimize
- ⌨️ **Vim-like** — Operadores `go`, `goo` para rangos

## 📦 Instalación

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "daddydiaz2/kilocode.nvim",
  version = "*",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("kilocode").setup()
    
    -- Keymaps (como opencode.nvim)
    vim.keymap.set({ "n", "x" }, "<C-a>", function()
      require("kilocode").ask("@this: ", { submit = false })
    end, { desc = "Preguntar a KiloCode…" })
    
    vim.keymap.set({ "n", "x" }, "<C-x>", function()
      require("kilocode").select()
    end, { desc = "Seleccionar acción de KiloCode…" })
    
    vim.keymap.set({ "n", "t" }, "<C-.>", function()
      require("kilocode").toggle()
    end, { desc = "Toggle KiloCode" })
    
    vim.keymap.set({ "n", "x" }, "go", function()
      return require("kilocode").operator()
    end, { desc = "Añadir rango a KiloCode", expr = true })
    
    vim.keymap.set("n", "goo", function()
      require("kilocode").ask("@this: ", { submit = true })
    end, { desc = "Enviar línea a KiloCode" })
  end,
}
```

## ⚙️ Configuración

```lua
vim.g.kilocode_opts = {
  -- Split al costado (como opencode.nvim)
  split = "vsplit",  -- "vsplit" = derecha, "split" = abajo
  autoscroll = true,
  
  -- Prompts personalizados
  prompts = {
    custom = { 
      prompt = "Revisa @this", 
      submit = true 
    },
  },
}
```

## 🚀 Uso

### Abrir/Cerrar (manual)

| Tecla | Acción |
|-------|--------|
| `<C-.>` | Toggle (abrir/cerrar) panel |
| `:Kilo` | Comando para toggle |
| `:KiloOpen` | Abrir panel |
| `:KiloClose` | Cerrar panel |

**IMPORTANTE:** No se abre automáticamente al iniciar Neovim. Tú decides cuándo usarlo.

### Enviar código

| Tecla | Modo | Acción |
|-------|------|--------|
| `<C-a>` | n, x | Abrir input con contexto |
| `<C-x>` | n, x | Seleccionar prompt |
| `go` | n, x | Operador (selección visual) |
| `goo` | n | Enviar línea actual |

### Contextos

| Placeholder | Descripción |
|-------------|-------------|
| `@this` | Línea actual o selección visual |
| `@buffer` | Contenido completo del buffer |
| `@selection` | Última selección visual |
| `@filename` | Nombre del archivo |
| `@filepath` | Ruta completa del archivo |
| `@file` | Archivo con contenido formateado |
| `@diagnostics` | Errores y warnings |

### Prompts Predefinidos

```vim
:KiloPrompt explain     " Explica el código
:KiloPrompt review      " Revisa corrección
:KiloPrompt fix         " Corrige errores
:KiloPrompt document    " Documenta
:KiloPrompt test        " Genera tests
:KiloPrompt optimize    " Optimiza
:KiloPrompt refactor    " Refactoriza
:KiloPrompt implement   " Implementa
```

O selecciona con `<C-x>` o `:KiloSelect`.

## 📋 Ejemplos

```vim
" Abrir panel y preguntar
<C-a>Explica @this<CR>

" Enviar selección para review
vip<C-x>review<CR>

" Corregir errores automáticamente
:KiloPrompt fix

" Toggle panel (abrir/cerrar)
<C-.>
```

## 🔄 Flujo de trabajo (como opencode.nvim)

1. **Trabajas normalmente** en Neovim
2. **Necesitas ayuda:** presionas `<C-a>` o `<C-.>`
3. **Se abre el panel** al costado (split)
4. **Envías tu código** con contexto
5. **KiloCode responde** en el panel
6. **Continúas trabajando** — el panel queda abierto o lo cierras con `<C-.>`

## 👤 Autor

**Daniel Diaz**
- GitHub: [@daddydiaz2](https://github.com/daddydiaz2)
- Email: daddydiaz2@gmail.com

## 🙏 Créditos

Inspirado en [opencode.nvim](https://github.com/nickjvandyke/opencode.nvim) de Nick van Dyke.

## 📄 Licencia

MIT © Daniel Diaz
