# Contributing to kilocode.nvim

¡Gracias por tu interés en contribuir a kilocode.nvim!

## Flujo de Trabajo con Ramas

Este proyecto usa un modelo de ramas:

- **`main`**: Código estable, probado y listo para producción
- **`dev`**: Rama de desarrollo donde se integran todas las nuevas características

### Cómo Contribuir

1. **Fork** el repositorio
2. Crea una **rama feature** desde `dev`:
   ```bash
   git checkout dev
   git pull origin dev
   git checkout -b feature/nueva-caracteristica
   ```
3. Haz tus cambios y **commit**:
   ```bash
   git add .
   git commit -m "feat: descripción de la característica"
   ```
4. **Push** a tu fork:
   ```bash
   git push origin feature/nueva-caracteristica
   ```
5. Abre un **Pull Request** hacia la rama `dev`

### Convenciones de Commit

Usamos [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` Nueva característica
- `fix:` Corrección de bug
- `docs:` Cambios en documentación
- `style:` Formateo, punto y coma faltante, etc.
- `refactor:` Refactorización de código
- `test:` Añadir o corregir tests
- `chore:` Tareas de mantenimiento

### Antes de Hacer Push

Asegúrate de:

1. Ejecutar el linter: `stylua .`
2. Verificar con luacheck: `luacheck lua/`
3. Probar que el plugin funciona en Neovim
4. Actualizar el CHANGELOG.md si es necesario

## Estructura de Versionado

Seguimos [Semantic Versioning](https://semver.org/):

- **MAJOR**: Cambios incompatibles
- **MINOR**: Nuevas características (backward compatible)
- **PATCH**: Corrección de bugs

## Proceso de Release

1. Cuando `dev` está estable, se crea un PR a `main`
2. Se actualiza la versión en los tags
3. Se mergea a `main`
4. Se crea un tag/release en GitHub

## Código de Conducta

Sé respetuoso y constructivo en todas las interacciones.

## Preguntas

¿Tienes preguntas? Abre un issue o contacta a:
- Daniel Diaz <daddydiaz2@gmail.com>
- GitHub: @daddydiaz2
