# Research: Entorno Tridimensional Realista (WeinSolar v2)

**Feature**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md) | **Fecha**: 2026-10-19

Cada decisión sigue el formato *Decision / Rationale / Alternatives considered*. Las versiones se verificaron el 2026-10-19 contra pub.dev y el registro npm.

---

## R1 — Motor 3D en Flutter: `flutter_scene`

**Decision**: Usar `flutter_scene: ^0.24.3` (MIT, publisher `bdero.dev`) como **única** librería de renderizado 3D de `apps/weinsolar-flutter`. Esto obliga a subir el SDK de Flutter de **3.44.2 a ≥ 3.47.1 stable**: desde la 0.21.0, `flutter_scene` exige `flutter: >=3.47.0`, y la 3.47.1 corrige el flag de Flutter GPU en escritorio.

- **Puesta en marcha**: ejecutar `dart run flutter_scene:init`. Genera `hook/build.dart` y registra `flutter_scene_generated/` en los assets del `pubspec.yaml`.
- **Flutter GPU**: en desarrollo se pasa `--enable-flutter-gpu`. Para dejarlo activado:
  - iOS/macOS: `FLTEnableFlutterGPU` en `Info.plist`.
  - Android: meta-data `EnableFlutterGPU` en el manifest.
  - Web: no hace falta nada; usa el backend WebGL2 integrado.
- **API usada**: `Scene`, `Node`, `SceneView` (widget), `PerspectiveCamera`, `DirectionalLight` con `DirectionalLightComponent`, `Node.shadowCastingMode`, `DirectionalShadowFilter`, `PhysicallyBasedMaterial`, `MeshGeometry` y `GeometryBuilder` (terreno procedural), `loadScene` y `EnvironmentMap`/`SkyEnvironment` (luz ambiental del cielo).
- **Luz del sol**: la `DirectionalLight` se ata al valor del slider Hora Solar (`SolarHourState.solarElevationDeg`) y al azimut solar fijo de cada mundo, a través de `SceneLightingState` (ver [data-model.md](data-model.md)).
- **Modelo de la nave**: `assets/models/lander.glb`. El hook de build lo convierte en `.fsceneb` al compilar y en ejecución se carga con `loadScene('assets/models/lander.glb')`. `Node.fromGlbAsset` no se usa, porque está pensado para modelos descargados.

**Rationale**:
- Es el paquete que pidió el usuario. Tiene PBR, luz direccional con sombras en cascada y carga de glTF/GLB, y funciona en iOS, Android, macOS, Windows, Linux y web, así que conserva las plataformas de la v1.
- Los assets se empaquetan al compilar, lo que cumple el Principio IV y FR-020.
- Subir la versión del SDK no cambia la tecnología base (sigue siendo Flutter), por lo que no hace falta enmienda constitucional. Queda registrado en *Complexity Tracking*.

**Restricción constitucional (Restricciones del Producto)**: `flutter_scene` trae los módulos `physics` y `audio`. **Queda prohibido importarlos** (`package:flutter_scene/physics.dart`, `audio.dart`), así como añadir `flutter_scene_rapier`. La física sigue resolviéndose en `SimulateDescentStepUseCase`. La compuerta de verificación es un grep en CI y en el quickstart.

**Alternatives considered**:
- *`flutter_scene` 0.20.0 (último compatible con Flutter 3.44)*: evita subir el SDK, pero se queda en una versión anterior al sistema de sombras actual y sin las mejoras de escritorio. Descartado.
- *`flutter3d` 0.8.3*: tiene PBR y sombras, pero 618 descargas y no es lo que pidió el usuario. Descartado.
- *Seguir con `CustomPainter` (v1)*: no ofrece volumen real, PBR ni sombras proyectadas (FR-007, FR-013). Descartado.

---

## R2 — Motor 3D en Angular: `angular-three` (Ngt) sobre `three`

**Decision**: Usar `angular-three@3.7.2`, `three@0.172.0` y `@types/three@0.172.0`, más su peer obligatorio `ngxtension@^7.3.1`, **manteniendo Angular 19.2**.

- **Por qué la 3.7.2**: `angular-three@4.x` exige `@angular/core >=20 <22`, mientras que la 3.7.2 declara `@angular/core >=19 <20` y `three >=0.148 <0.173`.
- **API usada** (verificada en los `.d.ts` de la 3.7.2): `provideNgtRenderer`, `NgtCanvas` (inputs `sceneGraph` y `shadows`), `extend`, `NgtArgs`, `injectStore`, `injectBeforeRender` e `injectLoader`.
- **Materiales PBR**:
  - Nave: `MeshPhysicalMaterial` (metalness, roughness y clearcoat del GLB).
  - Terreno: `MeshStandardMaterial`.
  - Luz ambiental: `HemisphereLight` con los colores de cielo y suelo del mundo.
- **Sol**: `DirectionalLight` con `castShadow`, y `shadow.camera` ajustada a la zona visible.
- **Cámara 360°**: `OrbitControls` se importa de `three/examples/jsm/controls/OrbitControls.js` y se registra con `extend`. Se configura con:
  - `enabled` solo en modo `orbit` (Hora Solar tras un éxito, FR-010);
  - `enablePan = false`;
  - zoom acotado (`minDistance`/`maxDistance`);
  - `minPolarAngle`/`maxPolarAngle` para que la cámara no baje del suelo;
  - `target` en la nave.
- **Modelo de la nave**: `public/models/lander.glb`, cargado con `injectLoader(() => GLTFLoader, () => 'models/lander.glb')`, donde `GLTFLoader` viene de `three/examples/jsm/loaders/GLTFLoader.js`.

**Rationale**:
- Es la librería que pidió el usuario y tiene la API declarativa más cercana a Angular (signals y componentes standalone).
- Quedarse en Angular 19 evita una migración mayor del framework que no aporta valor a esta feature.
- `OrbitControls` sale del propio paquete `three`, sin añadir `angular-three-soba`. Ese paquete obligaría a instalar 13 peers, entre ellos `three-stdlib`, `camera-controls` y `three-mesh-bvh`, lo que choca con la regla de «una única librería de renderizado 3D» y con «cero alucinaciones de paquetes».

**Alternatives considered**:
- *Subir a Angular 20/21 y usar `angular-three@4.2.4`*: la API es más moderna, pero exige migrar el framework, la CLI y los tests fuera del alcance de la v2. Queda como deuda para una feature futura.
- *`angular-three-soba` (`NgtsOrbitControls`, `injectGLTF`)*: es más cómodo, pero añade peers pesados. Descartado.
- *Usar `three` directamente sin binding*: no se integra con signals ni con la detección de cambios OnPush, y obliga a gestionar el ciclo de vida a mano. Descartado.

**Nota de interpretación constitucional**: `angular-three` es un *binding* de Angular sobre `three` y no un segundo motor de render, y `ngxtension` es una utilidad de Angular que exige `angular-three`. Se considera que el stack Angular usa **una** librería de renderizado 3D (`three`). Esta interpretación necesita el visto bueno del Arquitecto Principal (ver *Complexity Tracking*).

---

## R3 — Assets 3D (nave y terreno)

**Decision**:
- **Nave**:
  - Un único `lander.glb` con PBR metallic-roughness, ≤ 15 000 triángulos y ≤ 1 MB, y licencia CC0 o de creación propia.
  - Se guarda una copia idéntica en `apps/weinsolar-flutter/assets/models/lander.glb` y otra en `apps/weinsolar-angular/public/models/lander.glb`.
  - La equivalencia se verifica con un checksum SHA-256 registrado en el quickstart.
- **Estados visuales de la nave**: tres nodos con nombre dentro del GLB, `Lander_Intact`, `Lander_Destroyed` y `Thruster_Flame`, que se muestran u ocultan según el `LanderStatus`. No se generan geometrías nuevas en tiempo de ejecución.
- **Terreno**: se genera de forma **procedural y determinista** con un campo de alturas calculado en el dominio (`GenerateTerrainLayoutUseCase`, ver data-model). No se usa GLB para el terreno. Hay un patrón de relieve por mundo (Tierra: rocas y vegetación baja; Marte: rocas y dunas; Luna: cráteres; Titán: hielo ondulado), y la plataforma central es plana por construcción (FR-012).
- **Paleta de materiales**: los colores de superficie vienen de `TerrainTheme` (v1).
- **Angular**: `angular.json` añade `{ "glob": "**/*", "input": "public" }` a `assets`, porque ahora mismo está vacío.

**Rationale**:
- Un modelo compartido garantiza la paridad visual entre stacks.
- Generar el terreno en el dominio permite probar la planitud de la plataforma con tests unitarios puros, sin motor gráfico, y evita assets pesados por mundo.

**Alternatives considered**: un GLB de terreno por mundo (4 assets pesados, sin forma de probar la plataforma); un asset compartido mediante un paquete común entre apps (rompe la independencia de repositorios declarada en la v1).

---

## R4 — Modelo de iluminación, tintes y nitidez de sombras

**Decision**: un nuevo caso de uso puro, `ComputeSceneLightingUseCase`, calcula `SceneLightingState` a partir del mundo, la elevación solar y el azimut solar:

- **Dirección del sol**: `d = (cos e · sin a, sin e, cos e · cos a)`, con `e` = elevación y `a` = azimut solar del mundo (constante por mundo, para que el ocaso caiga sobre el horizonte que encuadra la cámara).
- **Color e intensidad directa**:
  - Se interpolan con `smoothstep` entre `sunColorDayHex` y `sunColorSunsetHex` del nuevo `LightingProfile` en el tramo de elevación `[0°, 20°]`.
  - Por debajo de 0° la intensidad se apaga en `twilightFadeDeg`: Tierra 6°, Marte 8° (crepúsculo largo por el polvo), Titán 10° y Luna 0° (corte abrupto, FR-018).
- **Luz ambiental (tinte de cielo sobre la nave)**:
  - Color del hemisferio superior: el color de cénit de `SkyOpticalProfile` (v1), interpolado por elevación.
  - Color del hemisferio inferior: `TerrainTheme.primarySurfaceHex`.
  - En Marte, cerca del ocaso, la luz directa toma `sunHaloHex`, que es azul frío. Así se consigue el «reflejo azulado» de FR-016 en las caras orientadas al sol.
  - En la Luna la intensidad ambiental es 0 y el color directo es blanco solar (FR-016, Luna sin tinte).
- **Nitidez de sombra (`shadowSoftness` ∈ [0, 1])**: Luna 0,0 (bordes nítidos y sombra totalmente oscura), Tierra 0,35, Marte 0,45 y Titán 0,9 (FR-015).
- **Sombras activas**: `castsShadows = e > 0°`. Con el sol bajo el horizonte no se proyectan sombras (FR-014).

**Rationale**: todo el tinte se deriva de las referencias científicas que la v1 ya documentó en `SkyOpticalProfile`, como pide FR-017. Las nuevas constantes de `LightingProfile` reutilizan la misma `scientificReference`. Los valores de nitidez reflejan la profundidad óptica relativa de cada atmósfera (Titán τ≫1, Luna τ=0).

**Validación de la paleta Weincode (FR-006)**: ningún color derivado de la escena puede coincidir con ninguno de los cuatro códigos. Debe quedar a una distancia euclídea RGB ≥ 48 de `#18084D`, `#5236FF` y `#A599FF`, y ≥ 16 de `#FFFFFF`.

El umbral es menor para el blanco porque la luz solar real es casi blanca (~5800 K). Por ejemplo, el blanco solar de la Luna, `#FFF8EE`, está a una distancia de ≈ 18 de `#FFFFFF`. El Principio I exige esa luz física, pero el blanco puro de la marca queda excluido.

Ejemplo de comprobación: el halo marciano `#6C93B8` está a ≈ 91 de `#A599FF` y a ≈ 120 de `#5236FF`. Un test unitario lo comprueba en ambos stacks (RN-13).

**Alternatives considered**: tintes fijos por mundo sin interpolar (sin continuidad, incumple FR-018); un cálculo de dispersión atmosférica físico en tiempo real (fuera del alcance y del presupuesto de rendimiento).

---

## R5 — Longitud de sombras (SC-004)

**Decision**: la longitud esperada de una sombra es `L = h / tan(e)`. Con e = 45°, L = h; con e = 10°, L ≈ 5,67·h. El volumen de la cámara de sombras de la luz direccional se centra en la nave y se dimensiona con `max(40 m, 6·h_nave / tan(max(e, 5°)))`. Por debajo de 5° la sombra puede salir del encuadre, lo que acepta el edge case «sol rasante».

**Rationale**: la geometría es exacta en el motor si la dirección de la luz es correcta. La verificación (SC-004) se hace midiendo en capturas un poste de referencia del terreno de altura conocida, de 2 m.

---

## R6 — Niveles de calidad «Alta» / «Básica» (FR-019, FR-022)

**Decision**:

| Parámetro | Alta | Básica |
|-----------|------|--------|
| Resolución del mapa de sombras | 2048² (Angular) / 3 cascadas (Flutter) | 1024² / 1 cascada |
| Filtro de sombra | suave, PCF con el radio de `shadowSoftness` | PCF básico (borde más duro, misma dirección y longitud) |
| Malla de terreno | 192 × 192 vértices | 64 × 64 vértices |
| Rocas o elementos decorativos | 100 % | 40 % |
| Luz ambiental basada en imagen | activa | sustituida por luz hemisférica |
| Densidad de píxel | nativa (máx. 2×) | 1× |

En los dos niveles se conservan el volumen de la nave, la dirección y la longitud de las sombras, los tintes, el corte abrupto de la Luna y la cabina (FR-022). Cambiar de nivel solo reconfigura la escena y nunca toca el estado del provider ni de la página (SC-010).

**Rationale**: los parámetros elegidos son los que más afectan al rendimiento en móviles de gama media (sombras, número de vértices y densidad de píxel) sin tocar lo que exige la constitución.

---

## R7 — Cámara (FR-010, FR-011)

**Decision**:
- **Modo `lateralFollow`** (descenso, misión fallida y aterrizaje exitoso antes de usar Hora Solar):
  - La cámara se coloca perpendicular al plano sol–nave, a una distancia que encuadra la nave y el punto de contacto: `distancia = clamp(altitudVisual · 1,4, 12 m, 120 m)`.
  - Apunta al punto medio entre la nave y el suelo y se suaviza con amortiguación exponencial.
  - No responde a la entrada del usuario.
- **Modo `orbit`** (Hora Solar desbloqueada):
  - Angular: `OrbitControls` (R2).
  - Flutter: `GestureDetector` (arrastre horizontal → azimut, arrastre vertical → elevación de cámara entre 5° y 60°) que llama al ya existente `SimulationProvider.updateCameraAzimuth`. No se añade ningún paquete de controles.
  - El teclado (flechas izquierda/derecha) gira 5° por pulsación en ambos stacks.
- **Reglas de modo**: `ResolveCameraModeUseCase`: `orbit` solo si `SolarHourState.isUnlocked`; en cualquier otro caso, `lateralFollow`.

**Alternatives considered**: `OrbitControls` también en Flutter (no existe en `flutter_scene`, y escribir un equivalente genérico va más allá de lo que hace falta).

---

## R8 — Estrategia de pruebas con motores gráficos

**Decision**: ni Flutter GPU ni WebGL están disponibles de forma fiable en `flutter test` ni en Karma con ChromeHeadless. Por eso:
1. Toda decisión visual comprobable (luz, sombras, modo de cámara, plataforma, paleta, parámetros de calidad) se calcula en **funciones puras**: casos de uso de dominio y mappers de UI (`SceneDescriptorMapper`), que se prueban con TDD.
2. Los componentes y widgets de escena son **finos**: aplican el descriptor al motor sin lógica propia.
3. Los tests de página sustituyen la escena por un *placeholder*:
   - Flutter: parámetro `sceneBuilder` inyectado en `SimulatorPage`.
   - Angular: override de `PlanetaryScene3dComponent` en `TestBed`.
4. La paridad con la v1 se prueba con **trayectorias de referencia**. Un fixture de 5 perfiles por mundo se genera con los casos de uso de la v1 antes de cualquier cambio, y la suite de la v2 los ejecuta con cambios de calidad y de cámara intercalados (SC-001, SC-010).
5. La verificación visual (SC-002 a SC-005 y SC-007) es manual y sigue la *Compuerta de Verificación Visual* descrita en [quickstart.md](quickstart.md).

---

## R9 — Autonomía (Principio IV, FR-020)

**Decision**:
- **Flutter**: los modelos van en el bundle y el formato `.fsceneb` se genera al compilar.
- **Angular**:
  - `lander.glb` se sirve como asset estático del propio build, del mismo origen.
  - Se **precarga una única vez** al arrancar, antes de la selección de mundo, y se mantiene en memoria. Así, tras la apertura no hace falta ninguna petición más y el ciclo completo funciona sin red (SC-009).
  - Ningún recurso (modelo, textura, mapa de entorno, decodificador) se carga desde un CDN.
  - Si en el futuro se usa compresión Draco o Meshopt, el decodificador también se empaqueta en local.

---

## R10 — Invariancia física (FR-001, FR-002)

**Decision**: no se modifica ningún archivo de `domain/usecase/simulate-descent-step*`, `evaluate-solar-hour*` ni de los adaptadores de constantes. La escena recibe el estado solo en modo lectura: los inputs y props no tienen *setters* de estado físico. Un test de arquitectura (grep en el quickstart) comprueba que `UI/ds/organisms/planetary-scene-3d` y `lib/ui/widgets/scene3d` no importan casos de uso de simulación.
