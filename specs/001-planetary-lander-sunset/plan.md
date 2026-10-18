# Implementation Plan: Descenso Planetario y Hora Solar (WeinSolar v1 — Dual Stack: Angular & Flutter)

**Branch**: `001-planetary-lander-sunset` | **Date**: 2026-10-18 | **Spec**: [specs/001-planetary-lander-sunset/spec.md](spec.md)  
**Input**: Feature specification from `/specs/001-planetary-lander-sunset/spec.md` + Directrices de planificación Dual-Stack (Angular + Flutter).

---

## Summary

**WeinSolar v1** es un simulador interactivo 3D de descenso planetario vertical y observación crepuscular ("Hora Solar") en cuatro cuerpos del sistema solar (**Tierra, Marte, Luna y Titán**). Una única especificación funcional ([spec.md](spec.md)) y una única Constitución ([.specify/memory/constitution.md](../../.specify/memory/constitution.md)) gobiernan dos implementaciones cliente 100 % autónomas y libres de librerías externas de física:

1. **🅰️ Implementación Web (`apps/weinsolar-angular`)**: Angular moderno (Standalone Components, Signals, Control Flow nativo `@if`/`@for`, `ChangeDetectionStrategy.OnPush`), TypeScript estricto, estilos en CSS nativo / Tailwind local y lienzo de simulación 3D sobre `<canvas>` con proyección 3D matemática nativa a 60 FPS, siguiendo estrictamente [.github/instructions/angular-instructions.md](../../.github/instructions/angular-instructions.md).
2. **💙 Implementación Multiplataforma (`apps/weinsolar-flutter`)**: Flutter con Dart puro en dominio, Material 3, gestión de estado limpia con `ChangeNotifier` (o Riverpod si el usuario solicita explícitamente agregar el paquete, respetando por defecto la plantilla obligatoria `ChangeNotifier` y la regla *Cero Alucinaciones de Paquetes* de [.github/instructions/flutter-instructions.md](../../.github/instructions/flutter-instructions.md)), y renderizado 3D a 60 FPS mediante `CustomPainter` + `Ticker` (`SingleTickerProviderStateMixin`).

---

## Technical Context

**Language/Version**:
- **Angular**: TypeScript 5.x (estricto, sin `any`), Angular 18/19+ (Standalone, Signals, `@if`/`@for`).
- **Flutter**: Dart 3.x (null-safety estricto), Flutter 3.x (Material 3).

**Primary Dependencies**:
- **Angular**: `@angular/core`, `@angular/common`, `@angular/router`, `rxjs` (única dependencia permitida en `domain` para contratos `Observable<T>`), CSS nativo / Tailwind CSS local. **Cero librerías externas pesadas y cero motores de física**.
- **Flutter**: SDK de Flutter (`flutter/material.dart`, `flutter/scheduler.dart` para `Ticker`, `vector_math` integrado para proyección 3D en `CustomPainter`). **Cero librerías externas de física ni paquetes no solicitados de `pub.dev`**.

**Storage**: N/A — 100 % en memoria / adaptador local estático (`CelestialBodyLocalAdapter`), sin cuentas de usuario, sin bases de datos remotas ni llamadas HTTP en tiempo de ejecución (**Principio IV**, **FR-023**).  
**Testing**:
- **Angular**: Jasmine / Karma o TestBed de Angular CLI (`ng test --watch=false`) con enfoque **Tests First (TDD)** por capa (`domain` → `infraestructure` → `UI`).
- **Flutter**: `flutter_test` (`flutter test`) con enfoque **Tests First (TDD)** validando `domain` en Dart puro antes de construir los widgets.

**Target Platform**:
- **Angular**: Navegadores modernos de escritorio y móvil (teclado `Space`/`ArrowUp` + soporte táctil/puntero).
- **Flutter**: Web, macOS, Windows, Linux, iOS y Android a 60 FPS.

**Project Type**: Monorepo demostrativo SDD con dos aplicaciones cliente independientes (`apps/weinsolar-angular` y `apps/weinsolar-flutter`).  
**Performance Goals**: 60 FPS estables en el bucle de simulación y renderizado 3D (mínimo 30 FPS en gama media según **SC-010**), latencia de telemetría $< 0.1\text{ s}$ (**SC-007**), carga de escena $< 5\text{ s}$ (**SC-011**) y reinicio $< 2\text{ s}$ (**SC-008**).  
**Constraints**:
- Prohibido usar librerías de física externas: la cinemática vertical (gravedad, resistencia atmosférica cuadrática, empuje, consumo y escala temporal) se resuelve con fórmulas estándar en `SimulateDescentStepUseCase`.
- Paleta de cabina y telemetría restringida estrictamente a `#18084D`, `#5236FF`, `#A599FF` y `#FFFFFF`, sin teñir el lienzo 3D (**Principio III**, **FR-021**).
- Código (clases, métodos, variables, archivos) en **inglés**; textos visibles de la UI en **español**.

**Scale/Scope**: 4 mundos jugables, 1 vista/página principal con 3 modos operativos (Selección de Mundo, Cabina de Descenso 3D, Observación Crepuscular "Hora Solar" 3D), ~20 archivos por stack siguiendo Clean Architecture estricta.

---

## Constitution Check

*GATE: Evaluado antes de Phase 0 y re-verificado tras el diseño de Phase 1.*

- [x] **Principio I — Fidelidad Astrofísica [NO NEGOCIABLE]**: Constantes documentadas en `research.md` y `data-model.md` con margen $< 1\%$ (**SC-005**): Tierra ($g = 9.81\text{ m/s}^2, \rho = 1.225\text{ kg/m}^3$), Marte ($g = 3.71\text{ m/s}^2, \rho = 0.020\text{ kg/m}^3$), Luna ($g = 1.62\text{ m/s}^2, \rho = 0$), Titán ($g = 1.352\text{ m/s}^2, \rho = 5.3\text{ kg/m}^3$), junto con referencias ópticas reales de misiones NASA/ESA (**FR-015**, **FR-016**).
- [x] **Principio II — Consecuencia del Impacto y Recompensa Crepuscular [NO NEGOCIABLE]**: Umbral único $|v_y| \le 2.0\text{ m/s}$ inclusivo (**FR-010**) y techo $1.5 \times h_0$ (**FR-024**). Si $|v_y| > 2.0\text{ m/s}$ o $h > 1.5 \times h_0$, `EvaluateSolarHourUseCase` bloquea por completo el acceso a Hora Solar (**FR-012**, **SC-004**).
- [x] **Principio III — Identidad Cromática Weincode en Cabina y Telemetría**: El HUD usa exclusivamente `#18084D`, `#5236FF`, `#A599FF` y `#FFFFFF`. La escena 3D (cielo, terreno, sonda e iluminación) está aislada por contrato y verificada mediante tests unitarios para no contener ningún color Weincode (**FR-021**).
- [x] **Principio IV — Autonomía en Cliente y Cero Dependencia Externa**: `CelestialBodyLocalAdapter` provee los datos en memoria local sin llamadas HTTP ni servicios externos (**FR-023**, **SC-009**).
- [x] **Restricciones del Producto**: Simulador 3D resuelto con cinemática nativa en el dominio y proyección 3D en `<canvas>` (Angular) y `CustomPainter` (Flutter), sin motores de física externos.

---

## Project Structure

### Documentation (this feature)

```text
specs/001-planetary-lander-sunset/
├── plan.md                                  # Este archivo (Plan Maestro Dual-Stack Angular + Flutter)
├── research.md                              # Phase 0: Calibración física, render 3D y referencias ópticas
├── data-model.md                            # Phase 1: Entidades, máquina de estados e invariantes RN-01..RN-08
├── quickstart.md                            # Phase 1: Comandos TDD y compuertas de verificación
├── contracts/
│   └── domain-and-ui-contracts.md           # Phase 1: Gateways, Casos de Uso y contrato cromático HUD
└── tasks.md                                 # Phase 2 output (/speckit-tasks command)
```

### Source Code (repository root)

```text
weincode-sdd-course/
├── AGENTS.md                                # Contexto global del repositorio (enlaza a este plan)
├── apps/
│   ├── weinsolar-angular/                   # 🅰️ Aplicación Web Angular
│   │   ├── AGENTS.md                        # Contexto técnico local Angular
│   │   └── src/app/
│   │       ├── config/
│   │       ├── domain/
│   │       ├── infraestructure/
│   │       └── UI/
│   └── weinsolar-flutter/                   # 💙 Aplicación Multiplataforma Flutter
│       ├── AGENTS.md                        # Contexto técnico local Flutter
│       ├── lib/
│       │   ├── config/
│       │   ├── domain/
│       │   ├── infrastructure/
│       │   └── ui/
│       └── test/
```

**Structure Decision**: Se adopta la arquitectura Dual-Stack en `/apps/weinsolar-angular` y `/apps/weinsolar-flutter` definida en el `README.md` del repositorio, aplicando en cada subproyecto la estructura de directorios estricta exigida por `.github/instructions/angular-instructions.md` (incluyendo la carpeta `infraestructure/` y `UI/`) y `.github/instructions/flutter-instructions.md` (`domain/`, `infrastructure/`, `ui/`, `config/`).

---

# 🅰️ PLAN DE DESARROLLO: ANGULAR (`apps/weinsolar-angular`)

Cumple al 100 % las reglas de [.github/instructions/angular-instructions.md](../../.github/instructions/angular-instructions.md).

## 1. Contexto Técnico Local (`apps/weinsolar-angular/AGENTS.md`)

Contenido declarativo exacto para `apps/weinsolar-angular/AGENTS.md`:

```markdown
# Contexto Técnico Local — WeinSolar Angular (`apps/weinsolar-angular`)

## Stack Declarado (Inmutable salvo enmienda constitucional)
- **Framework**: Angular (Standalone Components, Signals `signal()` / `computed()` / `input()` / `output()`, Control Flow nativo `@if`, `@for (...; track ...)`, `@switch`, `ChangeDetectionStrategy.OnPush`).
- **Lenguaje**: TypeScript estricto (`strict: true`, prohibido `any`, `String`, `Number`).
- **Estilos**: CSS nativo / Tailwind CSS local con variables CSS restringidas en cabina y telemetría a la paleta Weincode (`#18084D`, `#5236FF`, `#A599FF`, `#FFFFFF`).
- **Renderizado 3D y Bucle de Simulación**: HTML5 `<canvas>` con proyección 3D en perspectiva matemática nativa y `requestAnimationFrame` a 60 FPS (con pausa automática en `visibilitychange`/`blur`), sin motores de física externos ni dependencias pesadas.
- **Arquitectura e Inyección**: Clean Architecture estricta (`domain` → `infraestructure` → `UI` → `config`). Inyección con `inject()` en campos de clase. Unión `Gateway` abstracto → `Adapter` concreto exclusivamente en `src/app/config/app.config.ts`.
- **Autonomía**: 100 % en cliente con `CelestialBodyLocalAdapter` (prohibidas llamadas HTTP de red en tiempo de ejecución según Principio IV de la Constitución).
- **Idioma**: Código (clases, métodos, variables, archivos) en inglés; textos visibles de la UI en español.
```

---

## 2. Estructura de Carpetas Sugerida (Siguiendo `angular-instructions.md`)

> Respeta literalmente los nombres `infraestructure` y `UI` tal como ordena `.github/instructions/angular-instructions.md`.

```text
apps/weinsolar-angular/
├── AGENTS.md
├── package.json
├── tsconfig.json
└── src/
    ├── index.html
    ├── main.ts
    ├── styles.scss
    └── app/
        ├── config/
        │   ├── app.config.ts                                           # Providers: { provide: CelestialBodyGateway, useClass: CelestialBodyLocalAdapter }
        │   └── app.routes.ts                                           # Ruta lazy con loadComponent hacia SimulatorPageComponent
        ├── domain/                                                     # 🧠 Lógica de negocio pura (0 Angular salvo @Injectable/inject en usecases, + rxjs)
        │   ├── models/
        │   │   ├── celestial-body/
        │   │   │   ├── celestial-body.ts                               # Interfaces CelestialBody, SkyOpticalProfile, TerrainTheme
        │   │   │   └── gateway/
        │   │   │       └── celestial-body-gateway.ts                   # abstract class CelestialBodyGateway
        │   │   └── simulation/
        │   │       ├── lander-state.ts                                 # Interface LanderState, enum LanderStatus
        │   │       ├── mission-attempt.ts                              # Interface MissionAttempt, MissionOutcome
        │   │       └── solar-hour-state.ts                             # Interface SolarHourState
        │   └── usecase/
        │       ├── get-celestial-bodies.use-case.ts                    # Obtención de los 4 mundos y validación RN-01
        │       ├── get-celestial-bodies.use-case.spec.ts               # Test unitario de catálogo y constantes
        │       ├── simulate-descent-step.use-case.ts                   # Cinemática vertical 1D, drag, empuje, escala temporal, techo y umbral 2,0 m/s
        │       ├── simulate-descent-step.use-case.spec.ts              # Tests First: RN-01..RN-05, RN-07 y CA de User Story 1
        │       ├── evaluate-solar-hour.use-case.ts                     # Bloqueo por impacto (RN-06) e interpolación óptica crepuscular (RN-08)
        │       └── evaluate-solar-hour.use-case.spec.ts                # Tests First: RN-06, RN-08 y CA de User Story 2
        ├── infraestructure/                                            # 🔌 Implementaciones concretas locales (100% offline)
        │   ├── driven-adapter/
        │   │   └── celestial-body-local/
        │   │       ├── celestial-body-local.adapter.ts                 # extends CelestialBodyGateway (datos científicos Tierra, Marte, Luna, Titán)
        │   │       └── celestial-body-local.adapter.spec.ts            # Tests de adaptador local
        │   └── helpers/
        │       └── mappers/
        │           ├── celestial-body.mapper.ts                        # CelestialBodyMapper.fromRaw(raw: unknown): CelestialBody
        │           └── celestial-body.mapper.spec.ts                   # Tests de mapeo desde unknown
        └── UI/                                                         # 🎨 Presentación (Standalone, Signals, OnPush, Atomic Design)
            ├── ds/
            │   ├── atoms/
            │   │   ├── telemetry-badge/
            │   │   │   └── telemetry-badge.component.ts                # Indicador individual (altitud, velocidad segura/peligrosa, combustible, escala ×N)
            │   │   └── thruster-button/
            │   │       └── thruster-button.component.ts                # Botón de empuje táctil/clic + estado visual sin combustible
            │   ├── molecules/
            │   │   ├── world-card/
            │   │   │   └── world-card.component.ts                     # Tarjeta de mundo con nombre en español y gravedad superficial (FR-002)
            │   │   ├── solar-hour-slider/
            │   │   │   └── solar-hour-slider.component.ts              # Control continuo Hora Solar [-10°, 90°] + giro horizontal de cámara [0°, 360°)
            │   │   └── mission-result-banner/
            │   │       └── mission-result-banner.component.ts          # Resumen de éxito/fallo + botones "Reintentar" y "Cambiar mundo" (FR-011..013, FR-017)
            │   ├── organisms/
            │   │   ├── weincode-cockpit-hud/
            │   │   │   ├── weincode-cockpit-hud.component.ts           # Cabina morada (#18084D, #5236FF, #A599FF, #FFFFFF) con telemetría completa (FR-019..021)
            │   │   │   └── weincode-cockpit-hud.component.spec.ts      # Tests de telemetría y aislamiento cromático Weincode
            │   │   └── planetary-scene-3d/
            │   │       └── planetary-scene-3d.component.ts             # Lienzo 3D <canvas>: cámara 3ª persona, terreno 3D por mundo, sonda, sol y sombras (FR-027..030)
            │   └── templates/
            │       └── simulator-shell/
            │           └── simulator-shell.component.ts                # Layout que superpone el HUD Weincode sobre el lienzo 3D sin contaminarlo
            ├── main/
            │   └── main.component.ts                                   # Componente raíz (<router-outlet />)
            └── pages/
                └── simulator/
                    ├── simulator.component.ts                          # Orquesta casos de uso con signals, teclado (Space/ArrowUp), visibilidad y RAF a 60fps
                    └── simulator.component.spec.ts                     # Tests de integración de página con casos de uso mockeados
```

---

## 3. Plan de Pruebas Unitarias en Angular (Tests First — `RN` y `CA` antes de pintar la UI)

Antes de implementar cualquier componente en `src/app/UI/`, deben escribirse y pasar al 100 % las siguientes suites de pruebas unitarias:

### Suite 1: `get-celestial-bodies.use-case.spec.ts` y `celestial-body-local.adapter.spec.ts`
- **Test `RN-01 / FR-001 / FR-002 / SC-005` (Catálogo y fidelidad científica)**:
  - Verifica que el catálogo devuelve exactamente 4 mundos (`earth`, `mars`, `moon`, `titan`) con nombres en español (`Tierra`, `Marte`, `Luna`, `Titán`).
  - Verifica que las gravedades (`9.81`, `3.71`, `1.62`, `1.352`) y densidades atmosféricas (`1.225`, `0.020`, `0.0`, `5.3`) coinciden con la tabla constitucional dentro de un margen $< 1\%$.
  - Verifica que cada mundo incluye una `scientificReference` no vacía (**FR-016**) y que `ceilingAltitude === 1.5 * initialAltitude` (**FR-024**).

### Suite 2: `simulate-descent-step.use-case.spec.ts`
- **Test `CA-US1-1 / FR-003 / FR-004` (Inicio y caída gravitatoria diferenciada)**:
  - Dado un estado inicial en Marte ($g = 3.71\text{ m/s}^2$) con propulsor apagado, tras un paso $\Delta t$, la velocidad vertical es más negativa y la altitud disminuye.
- **Test `CA-US1-8 / RN-02 / FR-005` (Contraste Luna vs Tierra y resistencia nula en vacío)**:
  - En la Luna ($\rho = 0$), la aceleración de arrastre es exactamente `0` y la caída sigue $v_y(t) = v_0 - g_{\text{moon}} t$.
  - Dejando caer la sonda sin propulsor durante el mismo intervalo desde la misma altitud en Luna y Tierra/Titán, la velocidad de impacto y la desaceleración atmosférica difieren significativamente.
- **Test `CA-US1-2 / FR-006` (Frenado con propulsor y consumo proporcional)**:
  - Con `isThrusterActive = true` y `fuelPercentage > 0`, la magnitud de la velocidad de caída disminuye y `fuelPercentage` se reduce proporcionalmente a $\Delta t_{\text{sim}}$.
- **Test `CA-US1-5 / RN-03 / FR-007` (Agotamiento de combustible en vuelo)**:
  - Con `fuelPercentage === 0` e `isThrusterActive = true`, el empuje generado es `0`, el combustible permanece en `0.0` (sin valores negativos) y la sonda acelera hacia abajo bajo gravedad + resistencia.
- **Test `CA-US1-3, CA-US1-4, CA-US1-7 / RN-04 / FR-009 / FR-010 / SC-004` (Frontera exacta del umbral de impacto)**:
  - Contacto con la superficie (`altitude <= 0`) a $|v_y| = 2.0\text{ m/s}$ $\to$ `outcome: 'success'`, `status: 'landed'`, `isSolarHourUnlocked: true`.
  - Contacto con la superficie a $|v_y| = 2.1\text{ m/s}$ $\to$ `outcome: 'failedImpact'`, `status: 'crashed'`, `isSolarHourUnlocked: false`, con `failureReasonEs` informado.
- **Test `CA-US1-6 / RN-05 / FR-024` (Techo de pérdida de señal)**:
  - Si la sonda supera `1.5 * initialAltitude` (`> 750 m`), el intento pasa inmediatamente a `outcome: 'failedSignalLost'`, `status: 'lostSignal'`, `failureReasonEs: 'Misión fallida – señal perdida'` y `isSolarHourUnlocked: false`.
- **Test `RN-07 / FR-025 / FR-026` (Invariancia de trayectoria con factor de escala temporal)**:
  - Verifica que simular con `timeScale = 4` y $\Delta t_{\text{real}} = 0.01\text{ s}$ produce exactamente las mismas magnitudes físicas (`altitude`, `verticalVelocity`, `fuelPercentage`) que simular en tiempo real (`timeScale = 1`) con $\Delta t = 0.04\text{ s}$, y que `horizontalVelocity` es siempre `0` (**FR-008**).
- **Test `SC-002` (Alcanzabilidad con reserva $\ge 15\%$ de combustible)**:
  - Simula un perfil de frenado óptimo en Tierra, Marte, Luna y Titán desde condiciones iniciales hasta `altitude == 0` con $|v_y| \le 2.0\text{ m/s}$ y verifica que en los 4 mundos `remainingFuel >= 15`.

### Suite 3: `evaluate-solar-hour.use-case.spec.ts`
- **Test `CA-US2-6 / RN-06 / FR-012 / SC-004` (Bloqueo estricto tras fallo o reinicio)**:
  - Si `attempt.outcome !== 'success'` (`failedImpact`, `failedSignalLost`, `inProgress` o tras `reset`), `EvaluateSolarHourUseCase` devuelve `isUnlocked: false` y bloquea cualquier cambio de elevación solar.
- **Test `CA-US2-1..5 / FR-014 / FR-015 / FR-030` (Transiciones ópticas por mundo)**:
  - **Tierra**: al bajar `solarElevationDeg` de `65°` a `5°`, el horizonte transita de azul diurno a tonos naranjas/rojizos.
  - **Marte**: cerca del ocaso (`0°..15°`), el cielo ocre mantiene un `sunHaloColorHex` en el espectro azul frío (`B > R`).
  - **Luna**: a `65°`, `10°` y `-5°`, `zenithColorHex` y `horizonColorHex` son siempre `#000000`, `ambientLightIntensity === 0`, `shadowHardness === 1.0`, y al cruzar `< 0°` la iluminación directa cae abruptamente a `0`.
  - **Titán**: bruma ámbar/anaranjada con `shadowHardness <= 0.2` y oscurecimiento gradual.
- **Test `CA-US4-3 / RN-08 / FR-021` (No contaminación cromática Weincode en escena 3D)**:
  - Verifica que para ningún ángulo solar $\theta \in [-10^\circ, 90^\circ]$ en ninguno de los 4 mundos los colores de cielo, horizonte, luz o terreno coinciden con `#18084D`, `#5236FF` ni `#A599FF`.

---

## 4. Instrucciones para Argon en Antigravity (Prompt Maestro — Angular)

Copia y pega este prompt maestro para que el agente ejecute la construcción iterativa en Angular:

```markdown
Actúa como Tech Lead y Senior Angular Developer ejecutando la implementación de **WeinSolar v1** en `apps/weinsolar-angular`.

### 1. Lectura Obligatoria de Gobierno antes de escribir una sola línea
Lee y obedece estrictamente en este orden de precedencia:
1. `.specify/memory/constitution.md` (Principios I al IV y Restricciones 3D).
2. `specs/001-planetary-lander-sunset/spec.md`, `specs/001-planetary-lander-sunset/plan.md`, `specs/001-planetary-lander-sunset/data-model.md` y `specs/001-planetary-lander-sunset/contracts/domain-and-ui-contracts.md`.
3. `.github/instructions/angular-instructions.md` y `apps/weinsolar-angular/AGENTS.md`.

### 2. Reglas de Arquitectura y Stack No Negociables
- Respeta la estructura exacta `src/app/{config,domain,infraestructure,UI}` (mantén el nombre `infraestructure` y `UI` tal cual).
- `domain` NO importa nada de Angular (excepto `@Injectable` e `inject` en los casos de uso) ni de `infraestructure` o `UI`. Solo tipos puros y `rxjs`.
- `CelestialBodyGateway` DEBE ser una `abstract class` y vincularse a `CelestialBodyLocalAdapter` únicamente en `src/app/config/app.config.ts`.
- Cero llamadas HTTP en tiempo de ejecución y cero librerías externas de física o paquetes npm no autorizados.
- Componentes 100 % standalone, `ChangeDetectionStrategy.OnPush`, `inject()`, `signal()`, `computed()`, `input()`, `output()`, y control de flujo `@if` / `@for (...; track ...)`. Prohibido `any`.
- Código en inglés; todos los textos visibles de la UI en español.

### 3. Ciclo de Ejecución Iterativo (TDD Estricto — Tests First)
Ejecuta el desarrollo en estas 4 iteraciones verificables, corriendo `npm --prefix apps/weinsolar-angular test -- --watch=false` al final de cada una:

- **Iteración 1 (Domain & Unit Tests First)**:
  1. Crea los modelos en `src/app/domain/models/` (`CelestialBody`, `LanderState`, `MissionAttempt`, `SolarHourState`) y `CelestialBodyGateway`.
  2. Escribe PRIMERO los tests `get-celestial-bodies.use-case.spec.ts`, `simulate-descent-step.use-case.spec.ts` y `evaluate-solar-hour.use-case.spec.ts` cubriendo todas las reglas `RN-01` a `RN-08` y los Criterios de Aceptación (`2.0 m/s` éxito vs `2.1 m/s` fallo, techo `1.5 × h_0`, `fuel == 0`, resistencia nula en Luna, escala temporal invariante `×N`, reserva `>= 15%` en SC-002 y bloqueo de Hora Solar tras impacto).
  3. Implementa `GetCelestialBodiesUseCase`, `SimulateDescentStepUseCase` y `EvaluateSolarHourUseCase` hasta que todos los tests de `domain` pasen en verde.

- **Iteración 2 (Infraestructure Local & Mappers)**:
  1. Crea `CelestialBodyMapper` (`fromRaw(raw: unknown): CelestialBody`) y su `.spec.ts`.
  2. Crea `CelestialBodyLocalAdapter extends CelestialBodyGateway` con las constantes reales y referencias científicas de Tierra, Marte, Luna y Titán, junto con su `.spec.ts`.
  3. Registra `{ provide: CelestialBodyGateway, useClass: CelestialBodyLocalAdapter }` en `src/app/config/app.config.ts`.

- **Iteración 3 (Design System Weincode HUD & Tests de UI)**:
  1. Construye los átomos, moléculas y el organismo `WeincodeCockpitHudComponent` usando EXCLUSIVAMENTE los colores `#18084D`, `#5236FF`, `#A599FF` y `#FFFFFF`.
  2. Muestra altitud, velocidad vertical con indicador seguro/peligroso respecto a `2,0 m/s`, porcentaje de combustible (y aviso `"Sin combustible"` en `0%`), nombre del mundo, gravedad, techo `1,5 × h_0` con alerta de proximidad y factor de escala (`×2`, `×3`, `×4`).
  3. Añade controles de `"Reiniciar"` en vuelo, `"Reintentar"` y `"Cambiar mundo"` en resultado, y el deslizador `"Hora Solar"` + rotación horizontal de cámara solo cuando `isSolarHourUnlocked() === true`.

- **Iteración 4 (Escena 3D `<canvas>` a 60 FPS e Integración en `SimulatorComponent`)**:
  1. Implementa `PlanetaryScene3dComponent` con proyección 3D en `<canvas>`: cámara en tercera persona siguiendo la sonda durante el descenso (FR-027), terreno 3D característico por mundo alrededor de la zona plana de aterrizaje (FR-028), transición de cámara hacia el horizonte con rotación horizontal `cameraAzimuthDeg` al aterrizar con éxito (FR-029), e iluminación/sombras dinámicas según `solarElevationDeg` (FR-030), garantizando que ningún color Weincode tiña la escena 3D (FR-021).
  2. Conecta `SimulatorComponent` con bucle `requestAnimationFrame`, soporte de teclado (`Space`/`ArrowUp`) y botón táctil/ratón (FR-022), y pausa automática al perder foco (`visibilitychange`/`blur`).
  3. Ejecuta todos los tests unitarios y el build de producción (`npm --prefix apps/weinsolar-angular run build`), corrigiendo cualquier fallo hasta obtener 0 errores y 100 % de tests en verde.
```

---

# 💙 PLAN DE DESARROLLO: FLUTTER (`apps/weinsolar-flutter`)

Cumple al 100 % las reglas de [.github/instructions/flutter-instructions.md](../../.github/instructions/flutter-instructions.md).

## 1. Contexto Técnico Local (`apps/weinsolar-flutter/AGENTS.md`)

Contenido declarativo exacto para `apps/weinsolar-flutter/AGENTS.md`:

```markdown
# Contexto Técnico Local — WeinSolar Flutter (`apps/weinsolar-flutter`)

## Stack Declarado (Inmutable salvo enmienda constitucional)
- **Framework y Lenguaje**: Flutter 3.x + Dart 3.x (Material 3, null-safety estricto).
- **Gestión de Estado**: Estado local limpio basado en `ChangeNotifier` dentro de `lib/config/providers/` (o Riverpod únicamente si el usuario solicita explícitamente añadir la dependencia en `pubspec.yaml`, respetando la regla "Cero Alucinaciones de Paquetes" de `.github/instructions/flutter-instructions.md`).
- **Física y Renderizado 3D a 60 FPS**: Cinemática 100 % en Dart puro dentro de `lib/domain/usecase/` (cero librerías externas de física). Escena 3D renderizada con `CustomPainter` + proyecciones `Matrix4` y bucle de animación a 60 FPS mediante `SingleTickerProviderStateMixin` (`Ticker`), con pausa automática ante cambios de `AppLifecycleState`.
- **Arquitectura e Inyección**: Clean Architecture estricta (`lib/domain/`, `lib/infrastructure/`, `lib/ui/`, `lib/config/`). `domain` es 100 % Dart puro (prohibido importar `package:flutter/material.dart`). Todas las dependencias se inyectan por constructor.
- **Identidad Cromática y Autonomía**: Cabina y telemetría restringidas a `0xFF18084D`, `0xFF5236FF`, `0xFFA599FF` y `0xFFFFFFFF` sin contaminar el `CustomPainter` de la escena 3D. Ejecución 100 % offline con `CelestialBodyLocalAdapter`.
- **Idioma**: Código (clases, métodos, variables, archivos) en inglés; textos visibles en la UI en español.
```

---

## 2. Estructura de Carpetas Sugerida (Siguiendo `flutter-instructions.md`)

> Encaja exactamente en los 4 directorios raíz obligatorios de `.github/instructions/flutter-instructions.md` (`domain/`, `infrastructure/`, `ui/`, `config/`).

```text
apps/weinsolar-flutter/
├── AGENTS.md
├── pubspec.yaml
├── analysis_options.yaml
├── lib/
│   ├── main.dart                                                       # Punto de entrada: inyección de Adapters → UseCases → Providers y ThemeData Weincode
│   ├── domain/                                                         # 🧠 Lógica de Negocio (0 dependencias externas, 0 imports de Flutter)
│   │   ├── models/
│   │   │   ├── celestial_body/
│   │   │   │   ├── celestial_body.dart                                 # Entidades CelestialBody, SkyOpticalProfile, TerrainTheme
│   │   │   │   └── gateway/
│   │   │   │       └── celestial_body_gateway.dart                     # abstract class CelestialBodyGateway
│   │   │   └── simulation/
│   │   │       ├── lander_state.dart                                   # Entidad inmutable LanderState, enum LanderStatus
│   │   │       ├── mission_attempt.dart                                # Entidad MissionAttempt, enum MissionOutcome
│   │   │       └── solar_hour_state.dart                               # Entidad SolarHourState
│   │   └── usecase/
│   │       ├── get_celestial_bodies_use_case.dart                      # Obtención de los 4 mundos vía CelestialBodyGateway
│   │       ├── simulate_descent_step_use_case.dart                     # Fórmulas cinemáticas de gravedad, arrastre cuadrático, empuje, escala temporal y umbral 2,0 m/s
│   │       └── evaluate_solar_hour_use_case.dart                       # Bloqueo por impacto (RN-06) y cálculo óptico crepuscular por elevación solar
│   ├── infrastructure/                                                 # 🔌 Implementaciones concretas (100% local / offline)
│   │   ├── driven_adapters/
│   │   │   └── celestial_body_local_adapter.dart                       # class CelestialBodyLocalAdapter implements CelestialBodyGateway
│   │   └── helpers/
│   │       └── mappers/
│   │           └── celestial_body_mapper.dart                          # Función pura celestialBodyDataToEntity(Map<String, dynamic> raw)
│   ├── ui/                                                             # 🎨 Presentación (Material 3, 0 lógica de negocio)
│   │   ├── pages/
│   │   │   └── simulator_page.dart                                     # Pantalla principal con Ticker a 60fps, FocusNode (teclado) y ciclo de vida
│   │   └── widgets/
│   │       ├── world_selector_sheet.dart                               # Selección de los 4 mundos mostrando nombre y gravedad (FR-001, FR-002)
│   │       ├── planetary_scene_3d_painter.dart                         # CustomPainter 3D: cámara 3ª persona, terreno 3D, sonda, sol y sombras dinámicas (FR-027..030)
│   │       ├── weincode_cockpit_hud.dart                               # Cabina Weincode (#18084D, #5236FF, #A599FF, #FFFFFF) con telemetría en vivo (FR-019..021)
│   │       ├── thruster_control_button.dart                            # Control táctil/clic mantenido (GestureDetector) + indicador sin combustible (FR-022)
│   │       ├── solar_hour_control_panel.dart                           # Slider "Hora Solar" [-10°, 90°] + rotación horizontal de cámara [0°, 360°) (FR-014, FR-029)
│   │       └── mission_outcome_overlay.dart                            # Tarjeta de éxito/fallo con velocidad de contacto, motivo y botones Reintentar/Cambiar mundo
│   └── config/                                                         # ⚙️ Configuración, Estado e Inyección
│       ├── providers/
│       │   └── simulation_provider.dart                                # class SimulationProvider extends ChangeNotifier (inyecta UseCases, nunca el Gateway directo)
│       └── routes/
│           └── app_routes.dart                                         # Definición declarativa de rutas de la aplicación
└── test/                                                               # 🧪 Tests First (Dart puro + Widget tests)
    ├── domain/
    │   ├── get_celestial_bodies_use_case_test.dart
    │   ├── simulate_descent_step_use_case_test.dart
    │   └── evaluate_solar_hour_use_case_test.dart
    ├── infrastructure/
    │   └── celestial_body_local_adapter_test.dart
    └── ui/
        └── simulator_page_widget_test.dart
```

---

## 3. Plan de Pruebas Unitarias en Flutter (Tests First — `RN` del descenso, gravedad y óptica)

Los tests en `apps/weinsolar-flutter/test/domain/` se escriben **en Dart puro antes de crear cualquier widget** en `lib/ui/`:

### Suite 1: `test/domain/get_celestial_bodies_use_case_test.dart`
- **Test `RN-01 / FR-001 / SC-005` (Constantes astrofísicas reales)**:
  - Verifica con un mock/falso de `CelestialBodyGateway` y con `CelestialBodyLocalAdapter` que existen exactamente 4 mundos (`Tierra`, `Marte`, `Luna`, `Titán`).
  - Comprueba que `gravity` (`9.81`, `3.71`, `1.62`, `1.352`) y `atmosphericDensity` (`1.225`, `0.020`, `0.0`, `5.3`) tienen una desviación $< 1\%$ respecto a la tabla oficial.
  - Comprueba que `ceilingAltitude == 1.5 * initialAltitude` en los 4 mundos.

### Suite 2: `test/domain/simulate_descent_step_use_case_test.dart`
- **Test `RN-01 & RN-02` (Caída libre por gravedad y resistencia atmosférica por mundo)**:
  - En la Luna ($\rho = 0$), tras $\Delta t_{\text{sim}} = 1.0\text{ s}$ sin propulsor desde $v_0 = -15.0\text{ m/s}$, la nueva velocidad es exactamente $-15.0 - 1.62 = -16.62\text{ m/s}$ (cero arrastre atmosférico, **FR-005**).
  - En Titán ($\rho = 5.3\text{ kg/m}^3$) y Tierra ($\rho = 1.225\text{ kg/m}^3$), la resistencia atmosférica reduce la aceleración neta de caída en función cuadrática de $v_y$, demostrando velocidades de impacto distintas frente a la Luna (**CA-US1-8**).
- **Test `FR-006 & RN-03` (Empuje del propulsor y corte por tanque vacío)**:
  - Con `isThrusterActive: true` y `fuelPercentage: 50.0`, la velocidad vertical se reduce en magnitud y `fuelPercentage` disminuye proporcionalmente al tiempo simulado.
  - Con `fuelPercentage: 0.0` e `isThrusterActive: true`, el propulsor no produce empuje (**FR-007**) y el combustible permanece en `0.0`.
- **Test `RN-04 / FR-009 / FR-010 / CA-US1-7` (Umbral exacto de aterrizaje seguro: `2.0 m/s` vs `2.1 m/s`)**:
  - Contacto en `altitude <= 0` con `verticalVelocity = -2.0` $\to$ `MissionOutcome.success`, `LanderStatus.landed`, `isSolarHourUnlocked == true`.
  - Contacto en `altitude <= 0` con `verticalVelocity = -2.1` $\to$ `MissionOutcome.failedImpact`, `LanderStatus.crashed`, `isSolarHourUnlocked == false`.
- **Test `RN-05 / FR-024 / CA-US1-6` (Superación del techo de altitud `1.5 × h_0`)**:
  - Cuando la sonda supera `750.0 m` (`1.5 * 500.0`), el intento termina inmediatamente con `MissionOutcome.failedSignalLost`, `failureReasonEs: 'Misión fallida – señal perdida'` y `isSolarHourUnlocked == false`.
- **Test `RN-07 / FR-025 / FR-026` (Escala temporal acelerada sin alterar la física)**:
  - Verifica que las unidades devueltas en `LanderState` (`altitude`, `verticalVelocity`, `fuelPercentage`) están en unidades físicas reales de tiempo simulado y que `horizontalVelocity == 0.0` siempre (**FR-008**).
- **Test `SC-002` (Reserva mínima del 15 % de combustible)**:
  - Ejecuta una simulación completa de aterrizaje óptimo en cada uno de los 4 mundos y comprueba que todos aterrizan con $|v_y| \le 2.0\text{ m/s}$ y `remainingFuel >= 15.0`.

### Suite 3: `test/domain/evaluate_solar_hour_use_case_test.dart`
- **Test `RN-06 / FR-012 / SC-004` (Bloqueo total de Hora Solar tras impacto o señal perdida)**:
  - Verifica que si `attempt.outcome != MissionOutcome.success`, `EvaluateSolarHourUseCase` devuelve `isUnlocked: false` e impide modificar la posición solar.
- **Test `FR-015 / FR-030 / RN-08` (Fidelidad cromática del ocaso y aislamiento de paleta Weincode)**:
  - Verifica la transición azul $\to$ naranja/rojo en Tierra, cielo ocre con halo azul frío en Marte, cielo negro permanente `#000000` con corte abrupto en Luna (`ambientLightIntensity == 0.0`, `shadowHardness == 1.0`), y bruma ámbar difusa en Titán.
  - Verifica que ninguno de los colores ópticos generados coincide con `0xFF18084D`, `0xFF5236FF` ni `0xFFA599FF`.

---

## 4. Instrucciones para Argon en Antigravity (Prompt Maestro — Flutter)

Copia y pega este prompt maestro para que el agente construya la aplicación Flutter y el loop a 60 FPS:

```markdown
Actúa como Tech Lead y Senior Flutter Developer ejecutando la implementación de **WeinSolar v1** en `apps/weinsolar-flutter`.

### 1. Lectura Obligatoria de Gobierno antes de escribir código
Lee y obedece estrictamente en este orden de precedencia:
1. `.specify/memory/constitution.md` (Principios I al IV y Restricciones 3D).
2. `specs/001-planetary-lander-sunset/spec.md`, `specs/001-planetary-lander-sunset/plan.md`, `specs/001-planetary-lander-sunset/data-model.md` y `specs/001-planetary-lander-sunset/contracts/domain-and-ui-contracts.md`.
3. `.github/instructions/flutter-instructions.md` y `apps/weinsolar-flutter/AGENTS.md`.

### 2. Reglas de Arquitectura y Stack No Negociables
- Encaja todos los archivos exclusivamente en `lib/{domain,infrastructure,ui,config}` y `test/`.
- `lib/domain/` NO puede importar `package:flutter/material.dart` ni ningún paquete externo: solo Dart puro.
- Prohibido añadir paquetes de `pub.dev` no solicitados ni librerías de física externas.
- Inyección de dependencias por constructor en todas las capas: `Adapter` implementa `Gateway`; `UseCase` recibe `Gateway`; `SimulationProvider extends ChangeNotifier` recibe los `UseCases` (nunca llama al `Gateway` directamente); la `UI` consume `SimulationProvider` y dispara eventos sin lógica de negocio.
- Código en inglés; todos los textos visibles en la UI en español.

### 3. Ciclo de Ejecución Iterativo (TDD Estricto — Tests First + Loop 60 FPS)
Ejecuta el desarrollo en estas 4 iteraciones verificables, corriendo `flutter test` y `dart analyze` al final de cada una:

- **Iteración 1 (Domain Layer en Dart Puro & Tests First)**:
  1. Crea en `lib/domain/models/` las entidades `CelestialBody`, `LanderState`, `MissionAttempt`, `SolarHourState` y el contrato `abstract class CelestialBodyGateway`.
  2. Escribe PRIMERO los tests unitarios en `test/domain/` (`get_celestial_bodies_use_case_test.dart`, `simulate_descent_step_use_case_test.dart`, `evaluate_solar_hour_use_case_test.dart`) validando gravedad real, arrastre atmosférico cuadrático (nulo en la Luna), empuje y corte con tanque en `0%`, umbral exacto `2.0 m/s` (éxito) vs `2.1 m/s` (fallo), techo `1.5 × h_0` ("Misión fallida – señal perdida"), escala temporal `×N`, reserva `>= 15%` de combustible (SC-002) y bloqueo estricto de Hora Solar tras fallo.
  3. Implementa `GetCelestialBodiesUseCase`, `SimulateDescentStepUseCase` y `EvaluateSolarHourUseCase` hasta que `flutter test test/domain` pase al 100 %.

- **Iteración 2 (Infrastructure Layer & Config Provider)**:
  1. Crea la función pura `celestialBodyDataToEntity` en `lib/infrastructure/helpers/mappers/celestial_body_mapper.dart`.
  2. Crea `CelestialBodyLocalAdapter implements CelestialBodyGateway` en `lib/infrastructure/driven_adapters/celestial_body_local_adapter.dart` con los datos reales y referencias científicas de Tierra, Marte, Luna y Titán, más su test en `test/infrastructure/`.
  3. Crea `SimulationProvider extends ChangeNotifier` en `lib/config/providers/simulation_provider.dart` orquestando la selección de mundo, el tick de simulación, el reinicio/cambio de mundo y los controles de Hora Solar y acimut de cámara.

- **Iteración 3 (Escena 3D con `CustomPainter` y Loop de Animación a 60 FPS)**:
  1. Implementa `PlanetaryScene3dPainter extends CustomPainter` en `lib/ui/widgets/planetary_scene_3d_painter.dart` con proyección 3D en perspectiva:
     - Cámara en tercera persona siguiendo la altitud de la sonda con la superficie visible (FR-027).
     - Entorno 3D característico por mundo alrededor de una zona de aterrizaje plana: vegetación/rocas en Tierra, regolito rojizo y rocas en Marte, regolito gris con cráteres en Luna, terreno helado bajo bruma en Titán (FR-028).
     - Al aterrizar con éxito, transición de cámara hacia el horizonte solar permitiendo rotar horizontalmente la vista alrededor de la sonda (`cameraAzimuthDeg`, FR-029).
     - Iluminación, sombras de sonda/terreno y gradiente de cielo/halo solar controlados dinámicamente por `solarElevationDeg` (sombras duras sin luz ambiental en Luna; luz difusa en Titán; halo azul en Marte; Rayleigh naranja/rojo en Tierra, FR-015, FR-030), sin usar ningún color Weincode en el lienzo 3D (FR-021).
  2. En `SimulatorPage` (`SingleTickerProviderStateMixin`), sincroniza el loop de simulación a 60 FPS usando un `Ticker`, calculando el delta de tiempo real entre frames (`elapsed`) y pausando automáticamente el `Ticker` cuando la app pierde el foco (`WidgetsBindingObserver` / `AppLifecycleState`).

- **Iteración 4 (Widgets de Cabina Weincode Material 3 & Widget Tests)**:
  1. Construye `WeincodeCockpitHud`, `WorldSelectorSheet`, `ThrusterControlButton` (soportando teclado `LogicalKeyboardKey.space` / `arrowUp` y pulsación táctil mantenida con `GestureDetector`), `SolarHourControlPanel` y `MissionOutcomeOverlay` usando exclusivamente la paleta Weincode (`0xFF18084D`, `0xFF5236FF`, `0xFFA599FF`, `0xFFFFFFFF`).
  2. Crea `test/ui/simulator_page_widget_test.dart` verificando selección de mundo, telemetría en español, bloqueo de Hora Solar tras impacto y desbloqueo tras aterrizaje suave.
  3. Ejecuta `flutter test` y `dart analyze` hasta lograr 0 warnings, 0 errores y el 100 % de las pruebas aprobadas.
```

---

## Complexity Tracking

> Sin violaciones a la Constitución. Todos los principios (I–IV), las restricciones de renderizado 3D sin motor de física externo y las reglas de Clean Architecture de ambos stacks se cumplen íntegramente.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Ninguna | N/A | N/A |
