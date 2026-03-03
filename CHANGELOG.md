# Changelog

Todos los cambios notables de este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-03-03

### Añadido
- Integración completa con KiloCode CLI
- Ventana de terminal persistente (derecha, izquierda, arriba, abajo)
- Ventana de input separada con historial
- Contextos inteligentes: `@this`, `@buffer`, `@selection`, `@filename`, `@filepath`, `@file`, `@diagnostics`
- Prompts predefinidos: explain, review, fix, document, test, optimize, refactor, implement
- Operador `go` para rangos y selección visual
- Comandos: `:Kilo`, `:KiloAsk`, `:KiloPrompt`, `:KiloSelect`, `:KiloClose`, `:KiloNew`
- Keymaps intuitivas: `<C-a>`, `<C-x>`, `<C-.>`, `go`, `goo`
- Soporte para statusline
- Configuración flexible mediante `vim.g.kilocode_opts`
- Auto-scroll en terminal
- Reemplazo automático de contextos en prompts

### Inspirado en
- [opencode.nvim](https://github.com/nickjvandyke/opencode.nvim) por Nick van Dyke
