# Implementation Plan: Entorno Tridimensional Realista (WeinSolar v2 — Dual Stack: Angular & Flutter)

**Branch**: `002-realistic-3d-scene` | **Date**: 2026-10-19 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-realistic-3d-scene/spec.md` + directrices técnicas del usuario (Flutter: `flutter_scene`, `DirectionalLight` atada a Hora Solar, assets `.glb`; Angular: `angular-three` (Ngt), materiales PBR, `OrbitControls` para el giro de 360°).

## Summary

La v2 sustituye la escena pseudo-3D de la v1 (`CustomPainter` en Flutter y proyección manual en `<canvas>` en Angular) por un **render 3D real**: nave cargada desde un `.glb` con materiales PBR, terreno procedural con relieve y plataforma central plana, una luz direccional solar con sombras proyectadas atada al slider Hora Solar, y tintes de ocaso derivados de las referencias científicas de la v1.

La cabina Weincode sigue siendo una capa plana superpuesta. La cámara sigue a la sonda desde un ángulo lateral fijo durante el descenso y pasa a giro libre de 360° solo tras un aterrizaje exitoso. Un selector manual «Alta / Básica» ajusta el detalle.

**Toda la física y las reglas de mérito de la v1 quedan intactas.** Se garantiza con fixtures de trayectorias de referencia y con un contrato de escena de solo lectura.

Enfoque técnico ([research.md](research.md)):
- **Flutter**: `flutter_scene ^0.24.3`, lo que obliga a subir Flutter de 3.44.2 a ≥ 3.47.1.
- **Angular**: `angular-three 3.7.2` + `three 0.172.0` + `ngxtension`, manteniendo Angular 19, con `OrbitControls` y `GLTFLoader` del propio `three`.
- **Ambos stacks**: tres casos de uso puros nuevos (`ComputeSceneLighting`, `GenerateTerrainLayout`, `ResolveCameraMode`), que concentran toda la lógica comprobable.

## Technical Context

**Language/Version**:
- **Angular**: TypeScript ~5.7 estricto y Angular 19.2 (standalone, signals, `@if`/`@for`, OnPush). Sin cambios.
- **Flutter**: Dart ^3.10 y **Flutter ≥ 3.47.1 stable**. Hoy está instalado 3.44.2; la subida la exige `flutter_scene` ≥ 0.21.

**Primary Dependencies** (nuevas, solicitadas explícitamente por el usuario):
- **Flutter**:
  - `flutter_scene: ^0.24.3`: `Scene`, `SceneView`, `PerspectiveCamera`, `DirectionalLight`/`DirectionalLightComponent`, `PhysicallyBasedMaterial`, `MeshGeometry`/`GeometryBuilder`, `loadScene`.
  - Hook de build generado por `dart run flutter_scene:init`.
- **Angular**:
  - `angular-three@3.7.2`: `provideNgtRenderer`, `NgtCanvas`, `extend`, `NgtArgs`, `injectStore`, `injectBeforeRender`, `injectLoader`.
  - `three@0.172.0`: `MeshPhysicalMaterial`/`MeshStandardMaterial`, `DirectionalLight`, `HemisphereLight`, `OrbitControls` y `GLTFLoader` desde `three/examples/jsm`.
  - `ngxtension@^7.3.1` (peer de `angular-three`).
  - `@types/three@0.172.0` (dev).
- **Prohibidos**: `angular-three-soba`, `three-stdlib`, `flutter_scene_rapier` y los módulos `physics`/`audio` de `flutter_scene`.

**Storage**: N/A, todo en memoria. Los assets 3D van empaquetados en el bundle.

**Testing**:
- Angular: Jasmine/Karma (`npm test -- --watch=false`).
- Flutter: `flutter_test`.
- Estrategia R8: lógica visual en funciones puras con TDD, escena fina sustituida por un placeholder en los tests de página, fixtures de paridad con la v1 y compuerta visual manual.

**Target Platform**:
- Angular: navegadores de escritorio y móvil con WebGL2.
- Flutter: iOS (la carpeta actual), además de web (backend WebGL2 de `flutter_scene`) y macOS/Android si se añaden. En nativo hay que activar Flutter GPU (`FLTEnableFlutterGPU`).

**Project Type**: monorepo SDD con dos apps cliente independientes (`apps/weinsolar-angular`, `apps/weinsolar-flutter`).

**Performance Goals**:
- ≥ 30 imágenes por segundo en Alta en un portátil de gama media y en Básica en un móvil de gama media (SC-005). Objetivo de 60.
- Escena lista en < 5 s (SC-006).
- Cambio de calidad en < 2 s (FR-019).
- Latencia de telemetría < 0,1 s (heredado de la v1).

**Constraints**:
- Física inmutable (FR-001, FR-002).
- Una sola librería de render 3D por stack.
- Sin red tras la apertura (Principio IV).
- Escena libre de la paleta Weincode según RN-13.
- Código en inglés y textos de UI en español.

**Scale/Scope**:
- 4 mundos, 1 modelo GLB (≤ 1 MB, ≤ 15 000 triángulos), terreno de 400 m × 400 m.
- 3 casos de uso nuevos y ~10 archivos nuevos o modificados por stack.

## Constitution Check

*GATE: evaluado antes de Phase 0 y re-verificado tras el diseño de Phase 1.*

- [x] **Principio I — Fidelidad Astrofísica [NO NEGOCIABLE]**: las constantes físicas no cambian (RN-01, RN-09). Los tintes de luz, la luz ambiental y la nitidez de sombra (`LightingProfile`) se derivan de las `scientificReference` de la v1 (RN-14, FR-017). La Luna no tiene luz ambiental y su corte es abrupto.
- [x] **Principio II — Consecuencia del Impacto [NO NEGOCIABLE]**: `SimulateDescentStepUseCase` y `EvaluateSolarHourUseCase` no se tocan. La plataforma es plana, sin vuelco ni nuevas causas de fallo (RN-10). El giro de cámara de 360° queda bloqueado si no hay éxito (RN-11).
- [x] **Principio III — Identidad Cromática Weincode**:
  - El HUD es una capa hermana fuera del lienzo 3D.
  - RN-13 prohíbe que los colores de la escena sean los códigos Weincode y exige estar a una distancia ≥ 48 de los tres tonos violeta y ≥ 16 del blanco.
  - El selector de calidad usa solo la paleta.
  - Hay tests unitarios en ambos stacks.
- [x] **Principio IV — Autonomía**:
  - GLB y terreno son locales; el terreno es procedural.
  - En Angular el GLB se precarga al arrancar.
  - No hay CDN, decodificadores remotos ni cuentas. La compuerta grep comprueba que no haya `http(s)://` en la escena.
- [x] **Restricciones del Producto**:
  - Hay una librería de render 3D por stack: `flutter_scene` en Flutter; `three` en Angular, con el binding `angular-three` (ver Complexity Tracking).
  - Los assets se empaquetan en local.
  - La física sigue en el dominio con cinemática estándar, y queda prohibido importar los módulos de física de los motores (compuerta grep).
  - No hay cambio de tecnología base: subir Flutter 3.44 → 3.47 es una versión dentro del mismo stack.

**Re-evaluación post-diseño (Phase 1)**: PASS. [data-model.md](data-model.md) (RN-09 a RN-15) y [contracts/scene-rendering-contract.md](contracts/scene-rendering-contract.md) materializan cada punto. No introducen estado físico nuevo ni dependencias más allá de las listadas.

## Project Structure

### Documentation (this feature)

```text
specs/002-realistic-3d-scene/
├── plan.md                              # Este archivo
├── research.md                          # Phase 0: R1–R10 (motores, versiones, luz, sombras, calidad, cámara, tests)
├── data-model.md                        # Phase 1: VisualQuality, CameraMode, LightingProfile, SceneLightingState, TerrainLayout, RN-09..RN-15
├── quickstart.md                        # Phase 1: instalación, TDD, compuertas grep y compuerta visual V1–V12
├── contracts/
│   └── scene-rendering-contract.md      # Phase 1: casos de uso puros + contrato de escena + selector de calidad
├── checklists/requirements.md
└── tasks.md                             # Phase 2 (/speckit-tasks; no lo crea este comando)
```

### Source Code (repository root)

Leyenda: `+` nuevo · `~` modificado · `−` eliminado.

```text
apps/weinsolar-angular/
├── ~ package.json                                   # angular-three 3.7.2, three 0.172.0, ngxtension, @types/three
├── ~ angular.json                                   # assets: public/**
├── + public/models/lander.glb
└── src/app/
    ├── ~ config/app.config.ts                       # provideNgtRenderer()
    ├── domain/
    │   ├── models/
    │   │   ├── ~ celestial-body/celestial-body.ts   # + LightingProfile
    │   │   └── + scene/{visual-quality,camera-mode,scene-lighting-state,terrain-layout}.ts
    │   └── usecase/
    │       ├── + compute-scene-lighting.use-case.ts (+ .spec.ts)
    │       ├── + generate-terrain-layout.use-case.ts (+ .spec.ts)
    │       ├── + resolve-camera-mode.use-case.ts (+ .spec.ts)
    │       ├── + reference-trajectories.spec.ts + __fixtures__/reference-trajectories.json
    │       └──   simulate-descent-step / evaluate-solar-hour     # SIN CAMBIOS
    ├── infraestructure/
    │   ├── ~ driven-adapter/celestial-body-local/celestial-body-local.adapter.ts (+ spec)   # lightingProfile x4
    │   └── ~ helpers/mappers/celestial-body.mapper.ts (+ spec)                             # valida lightingProfile y RN-13
    └── UI/
        ├── ds/
        │   ├── + molecules/quality-toggle/quality-toggle.component.ts
        │   ├── ~ organisms/planetary-scene-3d/
        │   │   ├── ~ planetary-scene-3d.component.ts            # host de <ngt-canvas [sceneGraph] [shadows]>
        │   │   ├── + planetary-scene-graph.component.ts
        │   │   ├── + lander-model.component.ts                  # injectLoader(GLTFLoader), estados de nodos
        │   │   ├── + terrain-mesh.component.ts                  # BufferGeometry desde TerrainLayout, MeshStandardMaterial
        │   │   ├── + sun-light.component.ts                     # DirectionalLight + HemisphereLight
        │   │   ├── + scene-camera-rig.component.ts              # lateralFollow / OrbitControls (extend)
        │   │   └── + scene-descriptor.mapper.ts (+ .spec.ts)    # tabla de calidad R6
        │   ├── ~ organisms/weincode-cockpit-hud/...              # aloja QualityToggle
        │   └──   templates/simulator-shell/...                  # HUD como capa hermana (verificar)
        └── pages/simulator/
            ├── ~ simulator.component.ts                         # signals visualQuality, sceneLighting, terrainLayout, cameraMode
            └── ~ simulator.component.spec.ts                    # placeholder de escena + SC-010

apps/weinsolar-flutter/
├── ~ pubspec.yaml                                   # flutter_scene ^0.24.3; assets/models/; flutter_scene_generated/
├── + hook/build.dart                                # generado por flutter_scene:init
├── + assets/models/lander.glb
├── ~ ios/Runner/Info.plist                          # FLTEnableFlutterGPU = true
├── lib/
│   ├── domain/
│   │   ├── models/
│   │   │   ├── ~ celestial_body/celestial_body.dart # + LightingProfile
│   │   │   └── + scene/{visual_quality,camera_mode,scene_lighting_state,terrain_layout}.dart
│   │   └── usecase/
│   │       ├── + compute_scene_lighting_use_case.dart
│   │       ├── + generate_terrain_layout_use_case.dart
│   │       └── + resolve_camera_mode_use_case.dart
│   ├── infrastructure/
│   │   ├── ~ driven_adapters/celestial_body_local_adapter.dart
│   │   └── ~ helpers/mappers/celestial_body_mapper.dart
│   ├── config/providers/~ simulation_provider.dart  # visualQuality, sceneLighting, terrainLayout, cameraMode, setVisualQuality
│   └── ui/
│       ├── pages/~ simulator_page.dart              # sceneBuilder inyectable; Stack(escena, HUD)
│       └── widgets/
│           ├── − planetary_scene_3d_painter.dart    # sustituido
│           ├── + quality_toggle.dart
│           ├── ~ weincode_cockpit_hud.dart          # aloja QualityToggle
│           └── + scene3d/
│               ├── planetary_scene_view.dart        # SceneView + GestureDetector (orbit)
│               ├── lander_node_factory.dart         # loadScene('assets/models/lander.glb')
│               ├── terrain_geometry_builder.dart    # MeshGeometry/GeometryBuilder desde TerrainLayout
│               ├── sun_light_binding.dart           # DirectionalLight atada a SceneLightingState (slider Hora Solar)
│               └── scene_descriptor_mapper.dart
└── test/
    ├── domain/+ {compute_scene_lighting,generate_terrain_layout,resolve_camera_mode,reference_trajectories}_test.dart
    ├── infrastructure/~ celestial_body_local_adapter_test.dart
    ├── ui/+ scene_descriptor_mapper_test.dart
    ├── ui/~ simulator_page_widget_test.dart         # placeholder de escena + SC-010
    └── fixtures/+ reference_trajectories.json
```

**Structure Decision**: se mantiene la estructura dual-stack y Clean Architecture de la v1, con los nombres exactos de `.github/instructions/angular-instructions.md` (`infraestructure/`, `UI/ds/…`) y `.github/instructions/flutter-instructions.md` (`domain/`, `infrastructure/`, `ui/`, `config/`).

- La lógica nueva va en `domain/usecase` como funciones puras.
- El acoplamiento con el motor 3D queda confinado a `UI/ds/organisms/planetary-scene-3d/` (Angular) y `lib/ui/widgets/scene3d/` (Flutter).
- `domain` no importa nunca `three`, `angular-three` ni `flutter_scene`. Para los vectores, Flutter usa tipos propios del dominio (no `vector_math`), así que el dominio sigue siendo Dart puro.

## Fases de implementación (orden recomendado para `/speckit-tasks`)

1. **Preparación**:
   - Subir Flutter a ≥ 3.47.1.
   - Congelar los fixtures de trayectorias v1 en cada stack, *antes* de cualquier cambio.
2. **Dominio (TDD)**:
   - Modelos nuevos y `LightingProfile` en los 4 mundos.
   - `ComputeSceneLighting`, `GenerateTerrainLayout` y `ResolveCameraMode`.
   - Tests de RN-10 a RN-15.
3. **Infraestructura**: adaptador y mapper con `lightingProfile` y validación RN-13.
4. **Dependencias y assets** (solicitadas):
   - Flutter: `flutter_scene`, `flutter_scene:init`, `Info.plist`.
   - Angular: `angular-three`, `three`, `ngxtension`, assets `public/`.
   - `lander.glb` en ambos stacks.
5. **Escena por stack (US1 · P1)**:
   - Nave GLB con PBR, terreno procedural y sombra de descenso.
   - Cámara `lateralFollow` y HUD superpuesto.
6. **Hora Solar (US2 · P2)**:
   - `DirectionalLight` atada al slider, longitud de sombras, nitidez por mundo y tintes.
   - Apagado bajo el horizonte.
7. **Cámara de 360° (US3 · P3)**:
   - Angular: `OrbitControls` con restricciones.
   - Flutter: gestos.
   - Bloqueo fuera de Hora Solar.
8. **Calidad «Alta / Básica»**: selector en la cabina, `QualitySettings` y test SC-010.
9. **Compuertas**: grep (sección 5 del quickstart), `flutter analyze`, build de Angular y verificación visual V1 a V12.

## Riesgos

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| `flutter_scene` es pre-1.0 (cambios de API entre versiones menores) | Roturas al actualizar | Fijar `^0.24.3` con `pubspec.lock` versionado; confinar su uso a `lib/ui/widgets/scene3d/` |
| Flutter GPU no disponible en `flutter test` | Escena sin tests automáticos | Estrategia R8 (lógica pura + placeholder + compuerta visual) |
| `angular-three` 3.x ya no es la línea principal (la 4.x exige Angular 20 o superior) | Deuda técnica | Documentado en R2; migrar a Angular 20/21 + `angular-three` 4.x en una feature futura |
| Mapa de sombras insuficiente con el sol rasante en Básica | Sombras cortadas o borrosas | Cámara de sombras dinámica (R5); edge case aceptado por debajo de 5° |
| Rendimiento móvil en Alta (selector manual, sin bajada automática) | < 30 imágenes por segundo hasta que el usuario cambie | Básica cubre SC-005 en móvil; el selector está visible en la cabina desde la selección de mundo |
| Licencia o creación del GLB | Bloquea US1 | Modelo CC0 o de creación propia; requisitos de tamaño y nombres de nodos en R3 |

## Complexity Tracking

> Desviaciones que necesitan justificación y aprobación del Arquitecto Principal (Governance).

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Angular usa 3 paquetes para el render: `three` (motor), `angular-three` (binding) y `ngxtension` (peer del binding). La constitución permite «una única librería de renderizado 3D» | El usuario pidió explícitamente `angular-three` (Ngt). El binding es lo que permite integrar el motor con signals y OnPush según `angular-instructions.md`. Se interpreta que `three` es la **única** librería de render, y que `angular-three`/`ngxtension` son la capa de integración con Angular | `three` sin binding obliga a gestionar el ciclo de vida a mano dentro de los componentes, contra el patrón OnPush/signals. `angular-three-soba` se rechazó por sus 13 peers adicionales |
| Subir el SDK de Flutter de 3.44.2 a ≥ 3.47.1 | `flutter_scene` ≥ 0.21 (con las sombras y los fixes de escritorio actuales) exige `flutter >= 3.47.0` | Fijar `flutter_scene 0.20.0` (compatible con 3.44) deja el sistema de sombras antiguo y los fixes pendientes. No es un cambio de tecnología base, así que no requiere enmienda |
| `flutter_scene` incluye módulos `physics` y `audio` | El paquete los trae de serie; no se pueden excluir de la dependencia | Se prohíbe importarlos (compuerta grep). La física sigue en `SimulateDescentStepUseCase` |
