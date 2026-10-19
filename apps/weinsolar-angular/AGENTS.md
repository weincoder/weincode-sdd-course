# Contexto Técnico Local — WeinSolar Angular (`apps/weinsolar-angular`)

## Stack Declarado (Inmutable salvo enmienda constitucional)
- **Framework**: Angular (Standalone Components, Signals `signal()` / `computed()` / `input()` / `output()`, Control Flow nativo `@if`, `@for (...; track ...)`, `@switch`, `ChangeDetectionStrategy.OnPush`).
- **Lenguaje**: TypeScript estricto (`strict: true`, prohibido `any`, `String`, `Number`).
- **Estilos**: CSS nativo / SCSS con variables CSS restringidas en cabina y telemetría a la paleta Weincode (`#18084D`, `#5236FF`, `#A599FF`, `#FFFFFF`).
- **Renderizado 3D y Bucle de Simulación**: HTML5 `<canvas>` con proyección 3D en perspectiva matemática nativa y `requestAnimationFrame` a 60 FPS (con pausa automática en `visibilitychange`/`blur`), sin motores de física externos ni dependencias pesadas.
- **Arquitectura e Inyección**: Clean Architecture estricta (`domain` → `infraestructure` → `UI` → `config`). Inyección con `inject()` en campos de clase. Unión `Gateway` abstracto → `Adapter` concreto exclusivamente en `src/app/config/app.config.ts`.
- **Autonomía**: 100 % en cliente con `CelestialBodyLocalAdapter` (prohibidas llamadas HTTP de red en tiempo de ejecución según Principio IV de la Constitución).
- **Idioma**: Código (clases, métodos, variables, archivos) en inglés; textos visibles de la UI en español.
