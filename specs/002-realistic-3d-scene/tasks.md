---
description: "Lista de tareas de WeinSolar v2 — Entorno Tridimensional Realista (Dual Stack: Angular & Flutter)"
---

# Tasks: Entorno Tridimensional Realista (WeinSolar v2 — Dual Stack: Angular & Flutter)

**Input**: documentos de diseño en `/specs/002-realistic-3d-scene/`
**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/scene-rendering-contract.md](contracts/scene-rendering-contract.md), [quickstart.md](quickstart.md)

**Tests**: **INCLUIDOS.** El plan y el quickstart exigen *Tests First* (TDD), igual que en la v1. Cada test se escribe y se comprueba que **falla** antes de su implementación.

**Organización**:
- Las tareas se agrupan por historia de usuario: US1 (P1) volumen y perspectiva, US2 (P2) sombras y tintes de Hora Solar, US3 (P3) cámara.
- El selector de calidad (FR-019, FR-022) es transversal a las tres historias y tiene su propia fase, después de US1.
- Dentro de cada fase, las tareas de Angular y de Flutter tocan archivos distintos y suelen poder hacerse en paralelo `[P]`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: se puede ejecutar en paralelo (archivos distintos, sin dependencias pendientes).
- **[Story]**: US1, US2 o US3 según [spec.md](spec.md).

## Path Conventions

- **Angular**: `apps/weinsolar-angular/` → código en `src/app/{config,domain,infraestructure,UI}/`. Respetar literalmente `infraestructure` y `UI` ([angular-instructions.md](../../.github/instructions/angular-instructions.md)).
- **Flutter**: `apps/weinsolar-flutter/` → código en `lib/{domain,infrastructure,ui,config}/` y tests en `test/` ([flutter-instructions.md](../../.github/instructions/flutter-instructions.md)).
- **Reglas transversales**:
  - Código en inglés y textos de UI en español.
  - `domain` en TypeScript/Dart puro: nunca importa `three`, `angular-three`, `flutter_scene` ni `vector_math`.
  - **No se modifican** `simulate-descent-step*`, `evaluate-solar-hour*` ni sus equivalentes Dart (FR-001, RN-09).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: congelar la referencia física de la v1, subir el SDK e instalar las dependencias que pidió el usuario. Ver [research.md](research.md) R1 a R3 y R8.

> ⚠️ T001 a T004 se ejecutan **antes** de cualquier otro cambio de código, sobre el estado actual (commit v1 `46497dc` + documentación v2).

- [X] T001 [P] Crear el test de trayectorias de referencia de Flutter en `apps/weinsolar-flutter/test/domain/reference_trajectories_test.dart`.
  - **Perfiles (5 por mundo, en los 4 mundos)**: (a) caída libre sin propulsor; (b) propulsor continuo hasta pasar el techo de 1,5 × la altitud inicial; (c) perfil que toca a exactamente 2,0 m/s; (d) perfil que toca a 2,1 m/s; (e) pulsos alternos de 0,5 s hasta agotar el combustible. Cada perfil es una secuencia determinista de `(deltaSeconds = 1/60, thrusterActive)`.
  - **Uso de los casos de uso**: `SimulateDescentStepUseCase` y `GetCelestialBodiesUseCase` reales.
  - **Modo escritura**: con `--dart-define=WRITE_FIXTURES=true` escribe en `apps/weinsolar-flutter/test/fixtures/reference_trajectories.json`, por perfil, el `LanderState` cada 30 ticks y el `MissionAttempt` final.
  - **Modo normal**: compara con tolerancia 1e-9.
- [X] T002 Ejecutar T001 en modo escritura (`cd apps/weinsolar-flutter && flutter test test/domain/reference_trajectories_test.dart --dart-define=WRITE_FIXTURES=true`) y versionar `apps/weinsolar-flutter/test/fixtures/reference_trajectories.json`. Depende de T001.
- [X] T003 [P] Crear el spec equivalente de Angular en `apps/weinsolar-angular/src/app/domain/usecase/reference-trajectories.spec.ts`.
  - Mismos 5 perfiles × 4 mundos, usando `SimulateDescentStepUseCase` y `GetCelestialBodiesUseCase` reales vía `TestBed`.
  - **Modo «print»** (constante `PRINT_FIXTURES = true`): vuelca el JSON con `console.log`.
  - **Modo normal**: compara con `src/app/domain/usecase/__fixtures__/reference-trajectories.json` con tolerancia 1e-9.
- [X] T004 Ejecutar T003 en modo «print» (`cd apps/weinsolar-angular && npm test -- --watch=false --include='**/reference-trajectories.spec.ts'`), guardar la salida en `apps/weinsolar-angular/src/app/domain/usecase/__fixtures__/reference-trajectories.json`, poner `PRINT_FIXTURES = false` y confirmar que el spec pasa. Depende de T003.
- [X] T005 Subir el SDK de Flutter a ≥ 3.47.1 stable (`flutter upgrade`).
  - Verificar con `flutter --version`.
  - Ejecutar `cd apps/weinsolar-flutter && flutter test` para confirmar que la suite de la v1 y T001 siguen en verde con el SDK nuevo.
  - Si T001 falla por el cambio de SDK, **detenerse** e informar: los fixtures de T002 dejan de ser la referencia.
- [X] T006 Instalar `flutter_scene` en `apps/weinsolar-flutter/pubspec.yaml` y preparar su pipeline. Depende de T005.
  - Ejecutar `cd apps/weinsolar-flutter && flutter pub add flutter_scene:^0.24.3 && dart run flutter_scene:init`.
  - Verificar que se generan `apps/weinsolar-flutter/hook/build.dart` y la entrada `flutter_scene_generated/` en los assets de `pubspec.yaml`.
  - Añadir `assets/models/` a la sección `flutter.assets`.
- [X] T007 [P] Activar Flutter GPU de forma permanente añadiendo `<key>FLTEnableFlutterGPU</key><true/>` en `apps/weinsolar-flutter/ios/Runner/Info.plist` (R1).
- [X] T008 [P] Instalar las dependencias 3D de Angular en `apps/weinsolar-angular/package.json`.
  - Ejecutar `npm install angular-three@3.7.2 three@0.172.0 ngxtension@^7.3.1 && npm install -D @types/three@0.172.0`.
  - **No** instalar `angular-three-soba` ni `three-stdlib` (R2).
- [X] T009 [P] Configurar en `apps/weinsolar-angular/angular.json` (`build.options.assets` y `test.options.assets`) el valor `[{ "glob": "**/*", "input": "public" }]` y crear la carpeta `apps/weinsolar-angular/public/models/`.
- [X] T010 Añadir el modelo de la nave en `apps/weinsolar-flutter/assets/models/lander.glb` y una copia idéntica en `apps/weinsolar-angular/public/models/lander.glb`.
  - **Requisitos** (R3): PBR metallic-roughness, ≤ 15 000 triángulos, ≤ 1 MB, licencia CC0 o de creación propia.
  - **Nodos con nombre**: `Lander_Intact`, `Lander_Destroyed` y `Thruster_Flame`.
  - **Altura conocida y origen**: 3,0 m, con el origen en la base de las patas.
  - **Checksum**: registrar el SHA-256 de ambos archivos en `specs/002-realistic-3d-scene/quickstart.md` (sección 5).
  - **Si no hay un modelo disponible**: detenerse y pedir el asset al usuario; no generar ni descargar uno sin confirmación.
  - Depende de T006 y T009.
- [X] T011 [P] Actualizar el bloque «Stack Declarado» de `apps/weinsolar-flutter/AGENTS.md` con Flutter ≥ 3.47.1, `flutter_scene ^0.24.3`, Flutter GPU y la prohibición de importar `package:flutter_scene/physics.dart`, `audio.dart` y `flutter_scene_rapier`.
- [X] T012 [P] Actualizar el bloque «Stack Declarado» de `apps/weinsolar-angular/AGENTS.md`.
  - Añadir `angular-three 3.7.2`, `three 0.172.0` y `ngxtension`.
  - Indicar que `OrbitControls` y `GLTFLoader` se importan de `three/examples/jsm`.
  - Indicar la prohibición de `angular-three-soba` y `three-stdlib`.

**Checkpoint**: fixtures v1 versionados en ambos stacks, SDK y dependencias instalados, `lander.glb` disponible.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: modelos de dominio, `LightingProfile` de los 4 mundos, cálculo de iluminación, resolución del modo de cámara, mapper de escena y arranque del motor. Todas las historias dependen de esto.

**⚠️ CRITICAL**: ninguna historia de usuario puede empezar hasta completar esta fase.

### Tests First — Fundacional

- [X] T013 [P] Test de `ResolveCameraModeUseCase` en `apps/weinsolar-angular/src/app/domain/usecase/resolve-camera-mode.use-case.spec.ts`: `orbit` si `SolarHourState.isUnlocked`; `lateralFollow` para `SolarHourState.locked()` (RN-11).
- [X] T014 [P] Test equivalente en `apps/weinsolar-flutter/test/domain/resolve_camera_mode_use_case_test.dart`.
- [X] T015 [P] Test de `ComputeSceneLightingUseCase` (comportamiento común) en `apps/weinsolar-angular/src/app/domain/usecase/compute-scene-lighting.use-case.spec.ts`:
  - `sunDirection` normalizado y con `y = sin(e)` (tolerancia 1e-9) para e ∈ {65°, 45°, 10°, 0°, −10°};
  - `castsShadows == e > 0`;
  - elevación acotada a [−10°, 90°];
  - determinismo (dos llamadas iguales devuelven el mismo resultado);
  - `shadowSoftness` copiado de `LightingProfile` (RN-12, RN-15).
- [X] T016 [P] Test equivalente en `apps/weinsolar-flutter/test/domain/compute_scene_lighting_use_case_test.dart`.
- [X] T017 [P] Ampliar `apps/weinsolar-angular/src/app/infraestructure/helpers/mappers/celestial-body.mapper.spec.ts`:
  - el mapper produce `lightingProfile` con todos los campos de [data-model.md](data-model.md);
  - lanza un error de dominio si falta `lightingProfile`;
  - **RN-13**: todos los colores de `LightingProfile`, `SkyOpticalProfile` y `TerrainTheme` de los 4 mundos están a una distancia RGB ≥ 48 de `#18084D`, `#5236FF` y `#A599FF`, ≥ 16 de `#FFFFFF`, y no son exactamente ninguno de los cuatro.
- [X] T018 [P] Ampliar `apps/weinsolar-angular/src/app/infraestructure/driven-adapter/celestial-body-local/celestial-body-local.adapter.spec.ts`: los 4 mundos exponen `lightingProfile`; Luna con `ambientDayIntensity == 0` y `twilightFadeDeg == 0`; `scientificReference` igual a la de `SkyOpticalProfile` (RN-14).
- [X] T019 [P] Ampliar `apps/weinsolar-flutter/test/infrastructure/celestial_body_local_adapter_test.dart` con los mismos casos que T017 y T018.

### Implementación — Fundacional (Angular)

- [X] T020 [P] Crear los modelos de dominio en `apps/weinsolar-angular/src/app/domain/models/scene/`:
  - `visual-quality.ts`: `type VisualQuality = 'high' | 'basic'`.
  - `camera-mode.ts`: `type CameraMode = 'lateralFollow' | 'orbit'`.
  - `scene-lighting-state.ts`: interface `SceneLightingState` con `Vector3Like { x, y, z }` propio del dominio.
  - `terrain-layout.ts`: interfaces `TerrainLayout` y `TerrainFeature` con `kind: 'rock' | 'crater' | 'dune' | 'iceRidge' | 'vegetation'`.
- [X] T021 Añadir la interface `LightingProfile` y el campo `readonly lightingProfile: LightingProfile` a `CelestialBody` en `apps/weinsolar-angular/src/app/domain/models/celestial-body/celestial-body.ts`.
- [X] T022 Añadir `lightingProfile` a los 4 mundos en `apps/weinsolar-angular/src/app/infraestructure/driven-adapter/celestial-body-local/celestial-body-local.adapter.ts`, con los valores exactos de la tabla de [data-model.md](data-model.md). `scientificReference` se reutiliza de `SkyOpticalProfile`. Depende de T021.
- [X] T023 Mapear y validar `lightingProfile` (error si falta, sin valores por defecto) en `apps/weinsolar-angular/src/app/infraestructure/helpers/mappers/celestial-body.mapper.ts`. Depende de T021. T017 y T018 pasan en verde.
- [X] T024 [P] Implementar `ResolveCameraModeUseCase` en `apps/weinsolar-angular/src/app/domain/usecase/resolve-camera-mode.use-case.ts` (`@Injectable({ providedIn: 'root' })`). T013 pasa en verde.
- [X] T025 Implementar `ComputeSceneLightingUseCase` en `apps/weinsolar-angular/src/app/domain/usecase/compute-scene-lighting.use-case.ts`, siguiendo [research.md](research.md) R4 y la tabla `SceneLightingState`:
  - dirección `(cos e·sin a, sin e, cos e·cos a)`;
  - interpolación `smoothstep` del color solar entre día y ocaso en [0°, 20°];
  - fundido bajo el horizonte según `twilightFadeDeg` (Luna: intensidad 0 inmediata si e < 0);
  - colores ambientales del cielo (cénit interpolado) y del suelo (`TerrainTheme.primarySurfaceHex`);
  - `expectedShadowLengthRatio = 1/tan(e)` si e > 0, `null` en otro caso.

  Sin dependencias de `three`. T015 pasa en verde. Depende de T020 y T021.
- [X] T026 Registrar `provideNgtRenderer()` en `apps/weinsolar-angular/src/app/config/app.config.ts` y llamar a `extend` con las clases de `three` que se usarán (`Mesh`, `Group`, `DirectionalLight`, `HemisphereLight`, `MeshStandardMaterial`, `MeshPhysicalMaterial`, `BufferGeometry`, `PerspectiveCamera`) en `apps/weinsolar-angular/src/app/UI/ds/organisms/planetary-scene-3d/ngt-extend.ts`. Depende de T008.

### Implementación — Fundacional (Flutter)

- [X] T027 [P] Crear los modelos de dominio en `apps/weinsolar-flutter/lib/domain/models/scene/`:
  - `visual_quality.dart`: `enum VisualQuality { high, basic }`.
  - `camera_mode.dart`: `enum CameraMode { lateralFollow, orbit }`.
  - `scene_lighting_state.dart`: con `class Vector3Value { final double x, y, z; }` propia del dominio, sin `vector_math`.
  - `terrain_layout.dart`: `TerrainLayout`, `TerrainFeature` y `enum TerrainFeatureKind`.
- [X] T028 Añadir la clase `LightingProfile` y el campo `final LightingProfile lightingProfile` a `CelestialBody` en `apps/weinsolar-flutter/lib/domain/models/celestial_body/celestial_body.dart`.
- [X] T029 Añadir `lightingProfile` a los 4 mundos en `apps/weinsolar-flutter/lib/infrastructure/driven_adapters/celestial_body_local_adapter.dart`, con los mismos valores que T022. Depende de T028.
- [X] T030 Mapear y validar `lightingProfile` en `apps/weinsolar-flutter/lib/infrastructure/helpers/mappers/celestial_body_mapper.dart` (lanza una excepción de dominio si falta). Depende de T028. T019 pasa en verde.
- [X] T031 [P] Implementar `ResolveCameraModeUseCase` en `apps/weinsolar-flutter/lib/domain/usecase/resolve_camera_mode_use_case.dart`. T014 pasa en verde.
- [X] T032 Implementar `ComputeSceneLightingUseCase` en `apps/weinsolar-flutter/lib/domain/usecase/compute_scene_lighting_use_case.dart` con las mismas fórmulas que T025, en Dart puro con `dart:math`. T016 pasa en verde. Depende de T027 y T028.

### Mapper de escena (ambos stacks)

- [X] T033 [P] Test de `SceneDescriptorMapper` en `apps/weinsolar-angular/src/app/UI/ds/organisms/planetary-scene-3d/scene-descriptor.mapper.spec.ts`:
  - la tabla `QualitySettings` de R6 para `high` y `basic`;
  - `landerVisual` derivado de `LanderState` (`altitude`, `status`, `isThrusterActive`);
  - nodo visible por estado: `descending`/`landed` → `Lander_Intact`, `crashed`/`lostSignal` → `Lander_Destroyed`, y `Thruster_Flame` solo si `isThrusterActive` y `descending`;
  - el mapper no muta su entrada.
- [X] T034 [P] Test equivalente en `apps/weinsolar-flutter/test/ui/scene_descriptor_mapper_test.dart`.
- [X] T035 [P] Implementar `SceneDescriptor`, `QualitySettings` y `SceneDescriptorMapper.from(world, landerState, lighting, terrain, cameraMode, cameraAzimuthDeg, quality)` en `apps/weinsolar-angular/src/app/UI/ds/organisms/planetary-scene-3d/scene-descriptor.mapper.ts`. T033 pasa en verde.
- [X] T036 [P] Implementar el equivalente en `apps/weinsolar-flutter/lib/ui/widgets/scene3d/scene_descriptor_mapper.dart`. T034 pasa en verde.

**Checkpoint**: dominio y mapper en verde en ambos stacks; T001 y T003 siguen en verde (la física no se ha tocado).

---

## Phase 3: User Story 1 — Descender sobre un mundo con volumen y perspectiva real (Priority: P1) 🎯 MVP

**Goal**:
- La nave GLB con PBR desciende sobre un terreno procedural con relieve y plataforma plana.
- El sol está fijo a 65° y la sombra de la nave converge con su base.
- La cámara sigue a la sonda desde un ángulo lateral fijo.
- La cabina Weincode queda superpuesta y estática.
- Las misiones fallidas muestran la nave destruida.

**Independent Test**: descender en los 4 mundos en ambos stacks y comprobar:
- volumen y relieve visibles;
- convergencia de la sombra con la base de la nave;
- cabina inmóvil;
- trayectorias idénticas a la v1 (T001 y T003 en verde);
- pasos V1, V2, V9, V11 y V12 de [quickstart.md](quickstart.md).

### Tests First — US1

- [X] T037 [P] [US1] Test de `GenerateTerrainLayoutUseCase` en `apps/weinsolar-angular/src/app/domain/usecase/generate-terrain-layout.use-case.spec.ts`, para los 4 mundos y ambos niveles de calidad:
  - **RN-10**: `height == 0` exacto en todo vértice con `√(x²+z²) ≤ padRadiusMeters` (6,0), y ninguna `TerrainFeature` a menos de `padRadius + 2 m`;
  - **determinismo**: mismo resultado en dos llamadas;
  - **tamaño**: `resolution` 192 / 64 y `heights.length == resolution²`;
  - **tipo de relieve por mundo**: Luna con al menos 1 `crater`, Titán con `iceRidge`, Marte con `rock`/`dune`, Tierra con `rock`/`vegetation`;
  - **RN-15**: con `basic` el número de features es aproximadamente el 40 % de `high` (±1).
- [X] T038 [P] [US1] Test equivalente en `apps/weinsolar-flutter/test/domain/generate_terrain_layout_use_case_test.dart`.
- [X] T039 [P] [US1] Ampliar `apps/weinsolar-angular/src/app/UI/pages/simulator/simulator.component.spec.ts`:
  - sustituir `PlanetaryScene3dComponent` por un stub con `TestBed.overrideComponent`;
  - durante el descenso, el stub recibe un `descriptor` con `cameraMode == 'lateralFollow'` y `lighting` calculado a 65°;
  - el HUD (`app-weincode-cockpit-hud`) se renderiza como hermano del lienzo, no dentro de él (FR-005).
- [X] T040 [P] [US1] Ampliar `apps/weinsolar-flutter/test/ui/simulator_page_widget_test.dart`:
  - inyectar un `sceneBuilder` que devuelva un `Placeholder` con `Key('scene-placeholder')`;
  - comprobar que el HUD está en un `Stack` por encima de la escena;
  - comprobar que el descriptor que recibe el builder en descenso tiene `CameraMode.lateralFollow`.

### Implementación — US1 (dominio)

- [X] T041 [P] [US1] Implementar `GenerateTerrainLayoutUseCase` en `apps/weinsolar-angular/src/app/domain/usecase/generate-terrain-layout.use-case.ts`:
  - ruido de valor determinista con semilla derivada de `worldId` (PRNG propio, p. ej. mulberry32; prohibido `Math.random`);
  - patrón por mundo según R3;
  - alturas a 0 en la plataforma, con transición *smoothstep* entre `padRadius` y `padRadius + 4 m`;
  - memoización por `(worldId, quality)`.

  T037 pasa en verde.
- [X] T042 [P] [US1] Implementar el equivalente en `apps/weinsolar-flutter/lib/domain/usecase/generate_terrain_layout_use_case.dart` (mismo PRNG y mismas reglas, sin `dart:math Random`). T038 pasa en verde.

### Implementación — US1 (Angular)

- [X] T043 [P] [US1] Crear `LanderModelComponent` en `apps/weinsolar-angular/src/app/UI/ds/organisms/planetary-scene-3d/lander-model.component.ts`:
  - carga con `injectLoader(() => GLTFLoader, () => 'models/lander.glb')`, importando `GLTFLoader` de `three/examples/jsm/loaders/GLTFLoader.js`;
  - input `landerVisual`;
  - posición Y = `altitudeMeters`;
  - visibilidad de nodos según T035;
  - `castShadow`/`receiveShadow` en todas las mallas;
  - mantiene los materiales `MeshStandardMaterial`/`MeshPhysicalMaterial` del GLB;
  - sin URLs absolutas.
- [X] T044 [P] [US1] Crear `TerrainMeshComponent` en `apps/weinsolar-angular/src/app/UI/ds/organisms/planetary-scene-3d/terrain-mesh.component.ts`:
  - `BufferGeometry` desde `TerrainLayout.heights` (`sizeMeters` × `sizeMeters`), con normales calculadas;
  - `MeshStandardMaterial` con el color de `TerrainTheme.primarySurfaceHex` y la plataforma con `landingPadHex` mezclado en el borde (FR-021);
  - features instanciadas (rocas o cráteres con `secondaryFeatureHex`);
  - `receiveShadow` y, en las features, `castShadow`;
  - un poste de referencia de 2 m a 8 m del centro, en dirección perpendicular al sol (para SC-004).
- [X] T045 [P] [US1] Crear `SunLightComponent` en `apps/weinsolar-angular/src/app/UI/ds/organisms/planetary-scene-3d/sun-light.component.ts`:
  - `DirectionalLight` con `castShadow`, posición `target + sunDirection × 150`, color e intensidad de `SceneLightingState`;
  - `HemisphereLight` con `ambientSkyColorHex`/`ambientGroundColorHex`/`ambientIntensity`;
  - `shadow.mapSize` según `QualitySettings.shadowMapSize`.
- [X] T046 [P] [US1] Crear `SceneCameraRigComponent` (solo el modo `lateralFollow`) en `apps/weinsolar-angular/src/app/UI/ds/organisms/planetary-scene-3d/scene-camera-rig.component.ts`:
  - `PerspectiveCamera` perpendicular al plano sol–nave;
  - distancia `clamp(altitud × 1,4, 12, 120)`, apuntando al punto medio entre la nave y el suelo;
  - suavizado exponencial en `injectBeforeRender`;
  - sin respuesta a la entrada del usuario (R7, FR-010, FR-011).
- [X] T047 [US1] Crear `PlanetarySceneGraphComponent` en `apps/weinsolar-angular/src/app/UI/ds/organisms/planetary-scene-3d/planetary-scene-graph.component.ts`, que compone T043 a T046 y el fondo de cielo a partir de `SkyOpticalProfile`. Depende de T043, T044, T045 y T046.
- [X] T048 [US1] Reescribir `apps/weinsolar-angular/src/app/UI/ds/organisms/planetary-scene-3d/planetary-scene-3d.component.ts`:
  - **eliminar**: la proyección manual en `<canvas>` de la v1;
  - **inputs/outputs**: `descriptor = input.required<SceneDescriptor>()`, `cameraAzimuthChanged = output<number>()`, `sceneReady = output<void>()`;
  - **plantilla**: `<ngt-canvas [sceneGraph]="PlanetarySceneGraphComponent" [shadows]="true">`;
  - **`sceneReady`**: se emite cuando el GLB y el terreno están listos;
  - **componente**: `OnPush` y presentacional (no inyecta casos de uso).

  Depende de T026 y T047.
- [X] T049 [US1] Precargar el GLB una sola vez al arrancar, antes de la selección de mundo (Principio IV, R9), en `apps/weinsolar-angular/src/app/UI/ds/organisms/planetary-scene-3d/lander-model.component.ts`. Usar la caché de `injectLoader` o `GLTFLoader.loadAsync` invocado desde un `APP_INITIALIZER` en `apps/weinsolar-angular/src/app/config/app.config.ts`. Depende de T043.
- [X] T050 [US1] Orquestar en `apps/weinsolar-angular/src/app/UI/pages/simulator/simulator.component.ts`:
  - **nuevas señales**: `sceneLighting = computed(() => computeLighting.execute(world, solarHourState().isUnlocked ? solarElevationDeg : 65))`, `terrainLayout = computed(...)`, `cameraMode = computed(...)` y `sceneDescriptor = computed(() => SceneDescriptorMapper.from(...))`, con `visualQuality = signal<VisualQuality>('high')`;
  - **sustitución**: los inputs actuales de `<app-planetary-scene-3d>` se cambian por `[descriptor]`;
  - **invariante**: el bucle RAF y las llamadas a `SimulateDescentStepUseCase` no cambian.

  T039 pasa en verde. Depende de T048.
- [X] T051 [US1] Verificar o ajustar `apps/weinsolar-angular/src/app/UI/ds/templates/simulator-shell/simulator-shell.component.ts`:
  - el HUD está en una capa hermana con `position: absolute`, por encima del lienzo y con `pointer-events` solo en los controles;
  - el lienzo no recibe la clase ni las variables CSS de la paleta Weincode (FR-005, FR-006).

### Implementación — US1 (Flutter)

- [X] T052 [P] [US1] Crear `LanderNodeFactory` en `apps/weinsolar-flutter/lib/ui/widgets/scene3d/lander_node_factory.dart`:
  - carga con `loadScene('assets/models/lander.glb')`, convertido a `.fsceneb` por el hook de build;
  - localiza los nodos `Lander_Intact`, `Lander_Destroyed` y `Thruster_Flame`;
  - método `apply(LanderVisual)` que fija la posición Y y la visibilidad;
  - `shadowCastingMode` activo en las mallas.
- [X] T053 [P] [US1] Crear `TerrainGeometryBuilder` en `apps/weinsolar-flutter/lib/ui/widgets/scene3d/terrain_geometry_builder.dart`:
  - `MeshGeometry`/`GeometryBuilder` desde `TerrainLayout.heights`, con normales calculadas;
  - `PhysicallyBasedMaterial` con los colores de `TerrainTheme` y la plataforma integrada (FR-021);
  - features como nodos con `CuboidGeometry`/geometría de roca y sombras;
  - el poste de referencia de 2 m igual que en T044.
- [X] T054 [P] [US1] Crear `SunLightBinding` en `apps/weinsolar-flutter/lib/ui/widgets/scene3d/sun_light_binding.dart`:
  - `DirectionalLight` añadida vía `DirectionalLightComponent`, con dirección, color e intensidad de `SceneLightingState`;
  - sombras con `DirectionalShadowFilter` y número de cascadas de `QualitySettings.shadowCascades`;
  - luz ambiental mediante `SkyEnvironment`/`EnvironmentMap` (Alta) o una aproximación hemisférica (Básica);
  - método `apply(SceneLightingState, QualitySettings)`.
- [X] T055 [US1] Crear `PlanetarySceneView` en `apps/weinsolar-flutter/lib/ui/widgets/scene3d/planetary_scene_view.dart`:
  - `StatefulWidget` con `SceneView`, `Scene` y `PerspectiveCamera`;
  - cámara `lateralFollow` (misma fórmula que T046, con suavizado por frame);
  - `didUpdateWidget` aplica el `SceneDescriptor` mediante T052 a T054;
  - `onSceneReady` cuando el modelo y el terreno están listos;
  - fondo de cielo a partir de `SkyOpticalProfile`.

  Depende de T052, T053 y T054.
- [X] T056 [US1] Ampliar `apps/weinsolar-flutter/lib/config/providers/simulation_provider.dart`:
  - **inyección por constructor**: `ComputeSceneLightingUseCase`, `GenerateTerrainLayoutUseCase` y `ResolveCameraModeUseCase`;
  - **estado**: `VisualQuality _visualQuality = VisualQuality.high`;
  - **getters**: `visualQuality`, `sceneLighting` (65° si Hora Solar no está desbloqueada), `terrainLayout` (memoizado) y `cameraMode`;
  - **invariante**: `stepSimulation` no cambia.
- [X] T057 [US1] Modificar `apps/weinsolar-flutter/lib/ui/pages/simulator_page.dart`:
  - **sustitución**: `CustomPaint(painter: PlanetaryScene3dPainter(...))` se cambia por `PlanetarySceneView(descriptor: SceneDescriptorMapper.from(...))`;
  - **parámetro opcional** `Widget Function(SceneDescriptor)? sceneBuilder`, para los tests;
  - **capas**: `Stack(children: [escena, WeincodeCockpitHud(...)])`, con el HUD por encima.

  T040 pasa en verde. Depende de T055 y T056.
- [X] T058 [US1] Actualizar el registro de providers y casos de uso en `apps/weinsolar-flutter/lib/main.dart` (y `apps/weinsolar-flutter/lib/config/routes/app_routes.dart` si construye el provider) para inyectar los tres casos de uso nuevos. Depende de T056.
- [X] T059 [US1] Eliminar `apps/weinsolar-flutter/lib/ui/widgets/planetary_scene_3d_painter.dart` y sus referencias. Confirmar con `flutter analyze` sin errores. Depende de T057.

**Checkpoint US1**:
- MVP 3D jugable en ambos stacks.
- T001 y T003 en verde, lo que demuestra SC-001.
- Compuerta visual V1, V2, V9, V11 y V12 superada.

---

## Phase 4: Selector de calidad «Alta / Básica» (FR-019, FR-022 — transversal)

**Goal**: selector manual en la cabina, con «Alta» por defecto, que reconfigura la escena en < 2 s sin alterar el intento (SC-010).

**Independent Test**: cambiar el nivel a mitad del descenso en cada perfil de referencia y obtener el mismo resultado que el fixture; paso V8 de [quickstart.md](quickstart.md).

- [X] T060 [P] Test de paridad de calidad en `apps/weinsolar-angular/src/app/UI/pages/simulator/simulator.component.spec.ts`:
  - reproducir los perfiles (c) y (d) de T003 alternando `setVisualQuality('basic')` y `setVisualQuality('high')` cada 60 ticks;
  - el `MissionAttempt` final es idéntico al del fixture (RN-09, SC-010);
  - `sceneLighting()` es igual entre niveles (RN-15).
- [X] T061 [P] Test equivalente en `apps/weinsolar-flutter/test/ui/simulator_page_widget_test.dart`, con `SimulationProvider.setVisualQuality`.
- [X] T062 [P] Crear `QualityToggleComponent` en `apps/weinsolar-angular/src/app/UI/ds/molecules/quality-toggle/quality-toggle.component.ts`:
  - `value = input.required<VisualQuality>()`, `valueChange = output<VisualQuality>()`;
  - etiquetas «Calidad: Alta» / «Calidad: Básica»;
  - solo la paleta Weincode;
  - accesible por teclado (`role="radiogroup"`) y por toque.
- [X] T063 [P] Crear `QualityToggle` en `apps/weinsolar-flutter/lib/ui/widgets/quality_toggle.dart` (`SegmentedButton` con los colores del tema Weincode y textos en español).
- [X] T064 Integrar el selector en `apps/weinsolar-angular/src/app/UI/ds/organisms/weincode-cockpit-hud/weincode-cockpit-hud.component.ts` y en la pantalla de selección de mundo (`apps/weinsolar-angular/src/app/UI/ds/molecules/world-card/` o la plantilla de la página). Añadir `setVisualQuality(q)` en `apps/weinsolar-angular/src/app/UI/pages/simulator/simulator.component.ts`; no reinicia el RAF ni toca el estado físico. Depende de T062. T060 pasa en verde.
- [X] T065 Integrar `QualityToggle` en `apps/weinsolar-flutter/lib/ui/widgets/weincode_cockpit_hud.dart` y `apps/weinsolar-flutter/lib/ui/widgets/world_selector_sheet.dart`. Añadir `setVisualQuality(VisualQuality q)` en `apps/weinsolar-flutter/lib/config/providers/simulation_provider.dart` (solo `notifyListeners`, sin tocar `_landerState`, `_missionAttempt` ni `_solarHourState`). Depende de T063. T061 pasa en verde.
- [X] T066 [P] Aplicar `QualitySettings` en caliente sin recrear el lienzo ni recargar el GLB: `shadow.mapSize` + `shadow.map.dispose()`, regeneración de la `BufferGeometry` del terreno y `renderer.setPixelRatio(min(devicePixelRatio, maxPixelRatio))` vía `injectStore`. Archivos: `apps/weinsolar-angular/src/app/UI/ds/organisms/planetary-scene-3d/{sun-light,terrain-mesh,planetary-scene-graph}.component.ts`.
- [X] T067 [P] Aplicar `QualitySettings` en caliente en `apps/weinsolar-flutter/lib/ui/widgets/scene3d/{sun_light_binding,terrain_geometry_builder,planetary_scene_view}.dart` (cascadas, resolución del terreno, densidad de features y luz ambiental basada en imagen o hemisférica).

**Checkpoint**: el selector funciona en ambos stacks; T001, T003, T060 y T061 en verde.

---

## Phase 5: User Story 2 — Ver el atardecer proyectar sombras y teñir la nave (Priority: P2)

**Goal**:
- La `DirectionalLight` sigue al slider Hora Solar.
- Las sombras se alargan según `1/tan(e)` y desaparecen bajo el horizonte.
- La nitidez de sombra depende del mundo y la nave toma el tinte del ocaso de cada uno.

**Independent Test**: aterrizar con éxito en cada mundo, recorrer Hora Solar de 90° a −10° y comprobar los pasos V4 a V7 y V9 de [quickstart.md](quickstart.md).

### Tests First — US2

- [X] T068 [P] [US2] Ampliar `apps/weinsolar-angular/src/app/domain/usecase/compute-scene-lighting.use-case.spec.ts` con los casos por mundo:
  - **RN-12**: `expectedShadowLengthRatio` = 1,0 a 45° y ≈ 5,671 a 10° (error ≤ 1e-6); monótono creciente al bajar e de 89° a 1°; `null` con e ≤ 0.
  - **Marte**: a 2°, `sunColorHex` está a una distancia RGB < 30 de `#6C93B8` (reflejo azulado, FR-016).
  - **Tierra**: a 2°, el canal R supera ampliamente al B (naranja).
  - **Luna**: `ambientIntensity == 0` para toda e, y `sunIntensity` pasa de > 0 a e = +0,1° a exactamente 0 a e = −0,1° (corte abrupto).
  - **Titán**: `shadowSoftness == 0.9` y `sunIntensity` decrece de forma continua hasta −10°.
  - **Continuidad (FR-018)**: en Tierra, Marte y Titán, la diferencia de `sunIntensity` y de cada canal de color entre e y e+0,5° es ≤ 0,08.
  - **RN-13** sobre cada `sunColorHex` y `ambientSkyColorHex` interpolado, en pasos de 1°.
- [X] T069 [P] [US2] Test equivalente en `apps/weinsolar-flutter/test/domain/compute_scene_lighting_use_case_test.dart`.
- [X] T070 [P] [US2] Ampliar `apps/weinsolar-angular/src/app/UI/pages/simulator/simulator.component.spec.ts`:
  - tras un aterrizaje exitoso, mover el slider (`solar-hour-slider`) a 10° cambia `descriptor.lighting.sunDirection.y` a `sin(10°)`;
  - tras una misión fallida, el slider no existe y `lighting` se queda en 65° (Principio II).
- [X] T071 [P] [US2] Test equivalente en `apps/weinsolar-flutter/test/ui/simulator_page_widget_test.dart`, con `SolarHourControlPanel` y `SimulationProvider.updateSolarElevation`.

### Implementación — US2

- [X] T072 [US2] Ajustar `ComputeSceneLightingUseCase` en `apps/weinsolar-angular/src/app/domain/usecase/compute-scene-lighting.use-case.ts` hasta que T068 pase en verde (corte lunar, interpolación del halo marciano y fundido crepuscular). Si algún color del perfil incumple RN-13, corregir el valor en `celestial-body-local.adapter.ts` sin salir de la referencia científica.
- [X] T073 [US2] Ajustar `ComputeSceneLightingUseCase` en `apps/weinsolar-flutter/lib/domain/usecase/compute_scene_lighting_use_case.dart` hasta que T069 pase en verde.
- [X] T074 [P] [US2] Ampliar `SunLightComponent` en `apps/weinsolar-angular/src/app/UI/ds/organisms/planetary-scene-3d/sun-light.component.ts`:
  - **visibilidad**: `visible`/`castShadow = lighting.castsShadows`;
  - **volumen de sombra**: `shadow.camera` ortográfica centrada en la nave, de tamaño `max(40, 6·3/tan(max(e,5°)))` (R5);
  - **nitidez**: `shadow.radius` y `PCFSoftShadowMap` proporcionales a `shadowSoftness` en Alta, y `PCFShadowMap` en Básica;
  - **sombra lunar**: con `shadowSoftness == 0` la `HemisphereLight` queda en 0 (sombra totalmente negra).
- [X] T075 [P] [US2] Ampliar `SunLightBinding` en `apps/weinsolar-flutter/lib/ui/widgets/scene3d/sun_light_binding.dart` con el mismo comportamiento: sombras desactivadas si `!castsShadows`, cascadas con un rango ajustado a la elevación y filtro según `shadowSoftness`.
- [X] T076 [US2] Ajustar en `apps/weinsolar-angular/src/app/UI/ds/organisms/planetary-scene-3d/lander-model.component.ts` el `envMapIntensity` de los materiales PBR de la nave, para que el tinte ambiental del cielo se refleje en el casco (FR-016). En la Luna debe ser 0. Comprobar visualmente el paso V5 (reflejo azulado en Marte).
- [X] T077 [US2] Ajustar el equivalente en `apps/weinsolar-flutter/lib/ui/widgets/scene3d/lander_node_factory.dart` y `sun_light_binding.dart` (intensidad del entorno sobre `PhysicallyBasedMaterial`; 0 en la Luna).
- [X] T078 [US2] Verificar que el slider existente de `apps/weinsolar-angular/src/app/UI/ds/molecules/solar-hour-slider/solar-hour-slider.component.ts` y `apps/weinsolar-flutter/lib/ui/widgets/solar_hour_control_panel.dart` alimenta `solarElevationDeg` → `sceneLighting` → `DirectionalLight` en ambos sentidos y sin saltos (FR-018). T070 y T071 pasan en verde.

**Checkpoint US2**: compuerta visual V4 a V7 y V9 superada en ambos stacks, con el poste de 2 m: ≈ 2 m de sombra a 45° y ≈ 11,3 m a 10°, ±10 %.

---

## Phase 6: User Story 3 — Observar la escena desde el ángulo de cámara definido (Priority: P3)

**Goal**: giro libre de 360° alrededor de la nave solo en Hora Solar tras un éxito. Angular usa `OrbitControls` y Flutter gestos; las flechas del teclado giran 5° en ambos.

**Independent Test**: durante el descenso la cámara no responde a la entrada; en Hora Solar, una vuelta completa mantiene la nave centrada y la cabina inmóvil; tras un fallo no se puede girar. Pasos V2 y V3 de [quickstart.md](quickstart.md).

### Tests First — US3

- [X] T079 [P] [US3] Ampliar `apps/weinsolar-angular/src/app/UI/pages/simulator/simulator.component.spec.ts`:
  - durante el descenso, `ArrowLeft`/`ArrowRight` no cambian `descriptor.cameraAzimuthDeg`;
  - tras un éxito, cada pulsación cambia 5°, con valores normalizados a [0°, 360°);
  - tras un fallo, el azimut no cambia (RN-11).
- [X] T080 [P] [US3] Test equivalente en `apps/weinsolar-flutter/test/ui/simulator_page_widget_test.dart`, con `SimulationProvider.updateCameraAzimuth`: se ignora si `cameraMode != CameraMode.orbit`.

### Implementación — US3

- [X] T081 [US3] Ampliar `SceneCameraRigComponent` en `apps/weinsolar-angular/src/app/UI/ds/organisms/planetary-scene-3d/scene-camera-rig.component.ts` con el modo `orbit`:
  - **registro**: `OrbitControls` de `three/examples/jsm/controls/OrbitControls.js`, registrado con `extend` y montado con `NgtArgs` [camera, gl.domElement];
  - **activación**: `enabled = cameraMode === 'orbit'`;
  - **restricciones**: `enablePan = false`, `minDistance = 8`, `maxDistance = 40`, `minPolarAngle = 30°`, `maxPolarAngle = 85°` (la cámara no baja del suelo);
  - **objetivo y suavizado**: `target` en el centro de la nave y `enableDamping = true`;
  - **salida**: el evento `change` emite `cameraAzimuthChanged` con el azimut en grados;
  - **transición**: al pasar a `orbit`, la cámara se orienta hacia el horizonte del ocaso (`sunAzimuthDeg`).
- [X] T082 [US3] En `apps/weinsolar-angular/src/app/UI/pages/simulator/simulator.component.ts`:
  - conectar `(cameraAzimuthChanged)` y las flechas izquierda/derecha (±5°) a la actualización del azimut, solo si `cameraMode() === 'orbit'`;
  - retirar o ocultar el control de azimut por slider de la v1 en `apps/weinsolar-angular/src/app/UI/ds/molecules/solar-hour-slider/solar-hour-slider.component.ts`, que queda sustituido por `OrbitControls`.

  T079 pasa en verde. Depende de T081.
- [X] T083 [US3] Ampliar `PlanetarySceneView` en `apps/weinsolar-flutter/lib/ui/widgets/scene3d/planetary_scene_view.dart` con el modo `orbit`:
  - `GestureDetector` (arrastre horizontal → azimut; arrastre vertical → elevación de cámara acotada a [5°, 60°]), activo solo si `descriptor.cameraMode == CameraMode.orbit`;
  - la cámara orbita la nave a 18 m;
  - invoca `onCameraAzimuthChanged`;
  - `Focus` + `KeyboardListener` para las flechas (±5°);
  - al entrar en `orbit`, orientación inicial hacia `sunAzimuthDeg`.
- [X] T084 [US3] En `apps/weinsolar-flutter/lib/config/providers/simulation_provider.dart`, hacer que `updateCameraAzimuth` ignore la llamada si `cameraMode != CameraMode.orbit` y normalice a [0°, 360°). Retirar el control de azimut por slider en `apps/weinsolar-flutter/lib/ui/widgets/solar_hour_control_panel.dart`. T080 pasa en verde. Depende de T083.

**Checkpoint US3**: pasos V2 y V3 superados en ambos stacks; las tres historias funcionan de forma independiente.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T085 [P] Ejecutar las compuertas grep de la sección 5 de [quickstart.md](quickstart.md):
  - sin módulos `physics`/`audio` de `flutter_scene` ni `flutter_scene_rapier`;
  - la escena no importa casos de uso de simulación;
  - sin `http(s)://` en la escena;
  - sin `angular-three-soba`/`three-stdlib`;
  - SHA-256 idéntico del GLB en los dos stacks.

  Corregir cualquier fallo.
- [X] T086 [P] Comprobar que ningún archivo de `apps/weinsolar-angular/src/app/domain/` ni de `apps/weinsolar-flutter/lib/domain/` importa `three`, `angular-three`, `flutter_scene`, `vector_math` ni `package:flutter/` (`grep -rnE "from 'three|angular-three|flutter_scene|vector_math|package:flutter/"` sin resultados).
- [X] T087 [P] Ejecutar la suite completa de Flutter: `cd apps/weinsolar-flutter && flutter analyze && flutter test`. Incluye T001 en modo comparación y todo debe estar en verde.
- [X] T088 [P] Ejecutar la suite completa de Angular: `cd apps/weinsolar-angular && npm test -- --watch=false && npm run build`. Incluye T003 en modo comparación y todo debe estar en verde; el build no debe generar avisos de presupuesto por `three` sin justificar.
- [X] T089 Ejecutar la Compuerta de Verificación Visual V1 a V12 de [quickstart.md](quickstart.md) en ambos stacks (Angular: Chrome escritorio y móvil; Flutter: iOS con `--enable-flutter-gpu` y web) y registrar el resultado y las capturas en `specs/002-realistic-3d-scene/checklists/visual-verification.md`. Depende de T085 a T088.
- [X] T090 [P] Medir el rendimiento (V10, SC-005) y el tiempo de carga (V12, SC-006):
  - ≥ 30 imágenes por segundo en Alta en un portátil de gama media y en Básica en un móvil de gama media;
  - < 5 s desde que se elige mundo hasta `sceneReady`.

  Anotarlo en `specs/002-realistic-3d-scene/checklists/visual-verification.md`. Si no se cumple, ajustar los valores de `QualitySettings` en `scene-descriptor.mapper.ts` / `scene_descriptor_mapper.dart` sin tocar lo que protege FR-022.
- [X] T091 [P] Actualizar `README.md` (raíz) y `apps/weinsolar-flutter/README.md` con los nuevos prerrequisitos (Flutter ≥ 3.47.1, `--enable-flutter-gpu`, `dart run flutter_scene:init`) y los comandos de ejecución de la v2.

---

## Dependencies & Execution Order

### Phase Dependencies

```text
Phase 1 Setup ──▶ Phase 2 Foundational ──▶ Phase 3 US1 (MVP) ──┬──▶ Phase 4 Calidad ──┐
   (T001–T004 PRIMERO)                                         ├──▶ Phase 5 US2 ──────┼──▶ Phase 7 Polish
                                                               └──▶ Phase 6 US3 ──────┘
```

- **Setup (Phase 1)**: T001 → T002 y T003 → T004 son lo **primero**, antes de cualquier cambio de código. T005 → T006 → T010. T007, T008, T009, T011 y T012 en paralelo.
- **Foundational (Phase 2)**: depende de Setup y bloquea todas las historias.
- **US1 (Phase 3)**: depende de Foundational. Es el MVP: crea la escena, que US2, US3 y el selector de calidad amplían.
- **Calidad (Phase 4), US2 (Phase 5) y US3 (Phase 6)**: dependen de US1 (necesitan la escena). Son **independientes entre sí** y pueden hacerse en paralelo con personas distintas. Comparten algunos archivos (`sun-light.component.ts`, `planetary_scene_view.dart`, los specs de página), así que hay que coordinar los merges.
- **Polish (Phase 7)**: depende de todas las anteriores.

### User Story Dependencies

- **US1 (P1)**: solo depende de Foundational.
- **US2 (P2)**: depende de US1 (escena y `SunLight*`). Se prueba de forma independiente con el slider.
- **US3 (P3)**: depende de US1 (`SceneCameraRig`/`PlanetarySceneView`). Se prueba de forma independiente con la entrada de cámara.

### Within Each Phase

- Los tests se escriben y **fallan** antes de la implementación.
- Primero dominio, luego mapper o adaptador, luego componentes de escena, luego página o provider.
- En cada stack, la escena se compone (T047, T055) después de sus piezas (T043 a T046, T052 a T054).

---

## Parallel Execution Examples

### Phase 2 (Foundational)

```text
# Todos los tests fundacionales a la vez:
T013, T014, T015, T016, T017, T018, T019
# Modelos de dominio de ambos stacks:
T020 (Angular) ‖ T027 (Flutter)
# Casos de uso de cámara:
T024 (Angular) ‖ T031 (Flutter)
```

### User Story 1

```text
# Tests:
T037 ‖ T038 ‖ T039 ‖ T040
# Piezas de escena Angular en paralelo:
T043 ‖ T044 ‖ T045 ‖ T046
# Piezas de escena Flutter en paralelo (y en paralelo con Angular):
T052 ‖ T053 ‖ T054
```

### User Story 2

```text
T068 ‖ T069 ‖ T070 ‖ T071      # tests
T074 (Angular) ‖ T075 (Flutter) # luz y sombras por elevación
```

### User Story 3

```text
T079 ‖ T080                    # tests
T081 → T082 (Angular) ‖ T083 → T084 (Flutter)
```

---

## Implementation Strategy

### MVP First (solo User Story 1)

1. Phase 1: fixtures v1 (T001 a T004) **antes que nada**, y después SDK, dependencias y GLB.
2. Phase 2: dominio, mapper y arranque del motor.
3. Phase 3: US1 en un stack primero (recomendado Angular, porque `three` corre en Karma y el ciclo de feedback es más rápido) y después en el otro.
4. **Parar y validar**: T001 y T003 en verde, más la compuerta visual V1, V2, V9, V11 y V12.
5. Demo: nave con volumen descendiendo sobre relieve real con la cabina superpuesta.

### Entrega incremental

1. Setup + Foundational → base lista.
2. US1 → MVP 3D (demo).
3. Selector de calidad → desbloquea los móviles de gama media (SC-005 en Básica).
4. US2 → recompensa crepuscular con sombras y tintes (demo).
5. US3 → contemplación de 360° (demo).
6. Polish → compuertas y verificación visual completas.

### Estrategia en paralelo (2 personas)

- Tras Foundational: **persona A = Angular** y **persona B = Flutter**, cada una recorriendo US1 → Calidad → US2 → US3 en su stack.
- Los contratos compartidos ([data-model.md](data-model.md) y [contracts/scene-rendering-contract.md](contracts/scene-rendering-contract.md)) garantizan la paridad.

---

## Notes

- `[P]` = archivos distintos y sin dependencias pendientes.
- `[USx]` = trazabilidad con [spec.md](spec.md).
- **Prohibido** modificar los casos de uso de física de la v1. Si un test de trayectorias (T001, T003) falla, el error está en la capa nueva y nunca se corrige regenerando los fixtures.
- Cualquier dependencia no listada en [plan.md](plan.md) necesita confirmación explícita del usuario («cero alucinaciones de paquetes»).
- Hacer commit al cerrar cada tarea o grupo lógico; detenerse en cada checkpoint para validar.
