# Contexto Técnico Local — WeinSolar Angular (`apps/weinsolar-angular`)

## Stack Declarado (Inmutable salvo enmienda constitucional)
- **Framework**: Angular 19.2 (Standalone Components, Signals `signal()` / `computed()` / `input()` / `output()`, Control Flow nativo `@if`, `@for (...; track ...)`, `@switch`, `ChangeDetectionStrategy.OnPush`).
- **Lenguaje**: TypeScript estricto (`strict: true`, prohibido `any`, `String`, `Number`).
- **Estilos**: CSS nativo / SCSS con variables CSS restringidas en cabina y telemetría a la paleta Weincode (`#18084D`, `#5236FF`, `#A599FF`, `#FFFFFF`).
- **Renderizado 3D y Bucle de Simulación**: `angular-three 3.7.2`, `three 0.172.0` (`@types/three 0.172.0`) y `ngxtension`, junto con `requestAnimationFrame` a 60 FPS (con pausa automática en `visibilitychange`/`blur`). `OrbitControls` y `GLTFLoader` se importan directamente desde `three/examples/jsm/...`.
- **Prohibiciones de Paquetes**: Prohibido instalar o importar `angular-three-soba`, `three-stdlib` o motores de física externos.
- **Arquitectura e Inyección**: Clean Architecture estricta (`domain` → `infraestructure` → `UI` → `config`). `domain` no importa `three` ni `angular-three`. Inyección con `inject()` en campos de clase. Unión `Gateway` abstracto → `Adapter` concreto exclusivamente en `src/app/config/app.config.ts`.
- **Autonomía**: 100 % en cliente con `CelestialBodyLocalAdapter` y `public/models/lander.glb` local (prohibidas llamadas HTTP de red a orígenes externos en tiempo de ejecución según Principio IV de la Constitución).
- **Idioma**: Código (clases, métodos, variables, archivos) en inglés; textos visibles de la UI en español.
