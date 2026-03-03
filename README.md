# kilocode.nvim

Integra [KiloCode CLI](https://kilo.ai) con Neovim — potencia tu flujo de trabajo con asistencia AI directamente en tu editor.

![KiloCode.nvim](https://img.shields.io/badge/KiloCode-CLI-blue)
![Neovim](https://img.shields.io/badge/Neovim-%205.0+-green?logo=neovim)
![Lua](https://img.shields.io/badge/Made%20with-Lua-blueviolet?logo=lua)
![License](https://img.shields.io/badge/License-MIT-yellow)

> **Inspirado en [opencode.nvim](https://github.com/nickjvandyke/opencode.nvim)** de Nick van Dyke. Este plugin es una adaptación para KiloCode CLI con mejoras específicas.

## ✨ Características

- 🖥️ **Terminal integrada** — Ventana de terminal persistente al lado de tu código
- 📝 **Contextos inteligentes** — Usa placeholders como `@this`, `@buffer`, `@selection`
- 💬 **Input separado** — Ventana dedicada para escribir prompts con historial
- 🎯 **Prompts predefinidos** — explain, review, fix, document, test, optimize, refactor
- 🔄 **Continúa sesiones** — Mantén el contexto entre conversaciones
- ⌨️ **Vim-like** — Operadores, rangos y keymaps consistentes
- 🚀 **Rápido** — Implementado en Lua puro, sin dependencias pesadas

## 📦 Instalación

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "daddydiaz2/kilocode.nvim",
  version = "*", -- Última versión estable
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    ---@type kilocode.Opts
    vim.g.kilocode_opts = {
      -- Configuración opcional
      terminal = {
        position = "right",  -- "right", "left", "bottom", "top"
        width = 80,
        height = 20,
      },
    }

    -- Keymaps recomendadas
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

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'daddydiaz2/kilocode.nvim',
  requires = { 'nvim-lua/plenary.nvim' },
  config = function()
    require('kilocode').setup()
  end
}
```

### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'nvim-lua/plenary.nvim'
Plug 'daddydiaz2/kilocode.nvim'
```

## ⚙️ Requisitos

- **Neovim** >= 0.9.0
- **[KiloCode CLI](https://kilo.ai/docs/code-with-ai/platforms/cli)** instalado:
  ```bash
  npm install -g @kilocode/cli
  ```

## 🚀 Uso

### Comandos

| Comando | Descripción |
|---------|-------------|
| `:Kilo` | Abrir/cerrar terminal de KiloCode |
| `:KiloAsk [prompt]` | Abrir input con prompt opcional |
| `:KiloPrompt [nombre]` | Ejecutar prompt predefinido |
| `:KiloSelect` | Seleccionar prompt de lista |
| `:KiloClose` | Cerrar KiloCode |
| `:KiloNew` | Nueva sesión |

### Contextos

Usa estos placeholders en tus prompts:

| Placeholder | Contexto |
|-------------|----------|
| `@this` | Línea actual o selección visual |
| `@buffer` | Contenido completo del buffer |
| `@selection` | Selección visual guardada |
| `@filename` | Nombre del archivo actual |
| `@filepath` | Ruta completa del archivo |
| `@file` | Archivo con contenido formateado |
| `@diagnostics` | Errores y warnings del buffer |

### Prompts Predefinidos

| Nombre | Descripción |
|--------|-------------|
| `explain` | Explica el código y su contexto |
| `review` | Revisa corrección y legibilidad |
| `fix` | Corrige errores usando diagnósticos |
| `document` | Agrega comentarios de documentación |
| `test` | Genera tests |
| `optimize` | Optimiza rendimiento y legibilidad |
| `refactor` | Refactoriza siguiendo mejores prácticas |
| `implement` | Implementa funcionalidad descrita |

### Keymaps

| Tecla | Modo | Acción |
|-------|------|--------|
| `<C-a>` | n, x | Abrir input para preguntar |
| `<C-x>` | n, x | Seleccionar prompt |
| `<C-.>` | n, t | Toggle KiloCode |
| `go` | n, x | Operador (envía selección) |
| `goo` | n | Enviar línea actual |
| `<Esc>` | t | Salir a modo normal |
| `<C-q>` | t | Cerrar KiloCode |
| `<Tab>` | i (input) | Cambiar a terminal |
| `<Up>/<Down>` | i (input) | Navegar historial |

## 📋 Ejemplos

```vim
" Explicar función actual
<C-a>Explica @this<CR>

" Revisar código seleccionado
vip<C-x>review<CR>

" Corregir errores automáticamente
:KiloPrompt fix

" Enviar archivo completo con pregunta
:KiloAsk Revisa @buffer para verificar seguridad

" Nueva sesión manteniendo ventanas
:KiloNew
```

## ⚙️ Configuración

```lua
vim.g.kilocode_opts = {
  -- Configuración del servidor
  server = {
    cmd = "kilo",           -- Comando de KiloCode CLI
    args = {},              -- Argumentos adicionales
    env = {},               -- Variables de entorno
  },
  -- Configuración de la terminal
  terminal = {
    position = "right",     -- Posición: "right", "left", "bottom", "top"
    width = 80,             -- Ancho (para left/right)
    height = 20,            -- Alto (para top/bottom)
    border = "rounded",     -- Estilo de borde
    autoscroll = true,      -- Auto-scroll al final
  },
  -- Contextos personalizados
  contexts = {
    ["@custom"] = function(ctx)
      return "Mi contexto personalizado"
    end,
  },
  -- Prompts personalizados
  prompts = {
    myprompt = {
      prompt = "Analiza @this en detalle",
      submit = true,
    },
  },
}
```

## 🔄 Integración con statusline

```lua
-- lualine
require("lualine").setup({
  sections = {
    lualine_x = {
      { require("kilocode").statusline },
    },
  },
})
```

## 🛠️ Desarrollo

### Estructura del proyecto

```
kilocode.nvim/
├── lua/kilocode/
│   ├── init.lua      -- API principal
│   └── config.lua    -- Configuración
├── plugin/kilocode.lua  -- Comandos y highlights
└── README.md
```

### Tests

```bash
# Ejecutar tests (si están disponibles)
nvim --headless -c "PlenaryBustedDirectory tests"
```

## 🙏 Agradecimientos

- **[opencode.nvim](https://github.com/nickjvandyke/opencode.nvim)** por Nick van Dyke — Inspiración y estructura del proyecto
- **[KiloCode](https://kilo.ai)** — El increíble asistente de código AI
- **[Neovim](https://neovim.io)** — El mejor editor de texto

## 👤 Autor

**Daniel Diaz**
- GitHub: [@daddydiaz2](https://github.com/daddydiaz2)
- Email: daddydiaz2@gmail.com

## 📄 Licencia

[MIT](LICENSE) © Daniel Diaz

---

<p align="center">
  Hecho con ❤️ para la comunidad Neovim
</p>
