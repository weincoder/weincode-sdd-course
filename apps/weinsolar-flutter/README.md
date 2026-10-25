# WeinSolar v2 — Flutter 3D (`flutter_scene` + Impeller)

Simulador interactivo 3D de descenso planetario vertical y observación crepuscular (**Hora Solar**) implementado con **Flutter 3.41+**, **Impeller (`flutter_gpu`)** y **`flutter_scene` 0.24.3**, bajo arquitectura limpia (Domain / Infrastructure / UI / Config).

---

## Requisitos y Ejecución con Flutter GPU (`--enable-flutter-gpu`)

El renderizado 3D nativo utiliza **Flutter GPU** sobre el motor **Impeller** junto con el hook de compilación de shaders en `hook/build.dart`.

```bash
# 1. Instalar dependencias
flutter pub get

# 2. Análisis estático y suite de pruebas (Dominio + Widget tests)
flutter analyze
flutter test

# 3. Ejecutar en macOS / iOS / Android con Flutter GPU habilitado
flutter run -d macos --enable-flutter-gpu
```

---

## Arquitectura del Entorno 3D (`lib/ui/widgets/scene3d/`)

- **`SceneDescriptorMapper`** (`scene_descriptor_mapper.dart`): Traduce el estado de dominio puro (`CelestialBody`, `LanderState`, `SceneLightingState`, `TerrainLayout`, `CameraMode`, `VisualQuality`) a un descriptor inmutable de escena.
- **`LanderNodeFactory`** (`lander_node_factory.dart`): Carga el activo glTF 2.0 `assets/models/lander.glb` y conmuta la visibilidad de los nodos `Lander_Intact`, `Lander_Destroyed` y `Thruster_Flame`.
- **`TerrainGeometryBuilder`** (`terrain_geometry_builder.dart`): Construye la malla de altura (`MeshGeometry.fromArrays`) con plataforma de aterrizaje integrada en `(0, 0, 0)`, elementos superficiales procedurales (`rock`, `crater`, `dune`, `iceRidge`, `vegetation`) y el poste vertical de referencia de `2,0 m` para verificar la longitud geométrica de sombra (`RN-12`).
- **`SunLightBinding`** (`sun_light_binding.dart`): Sincroniza `DirectionalLight` con cascadas de sombras (`2` en Calidad Alta `2048×2048` PCSS, `1` en Calidad Básica `1024×1024` PCF fijo) y `GradientSkySource` (`environmentIntensity = 0` en el vacío lunar `RN-11`).
- **`PlanetarySceneView`** (`planetary_scene_view.dart`): Gestiona el ciclo de vida del `Scene`, cámara lateral suave (`CameraMode.lateralFollow`) durante el descenso y cámara orbital interactiva (`CameraMode.orbit`) durante la Hora Solar desbloqueada.

---

## Contrato del Activo 3D (`assets/models/lander.glb`)

- **Formato**: glTF 2.0 Binary (`.glb`), `≤ 5 MB`, `≤ 15 000` triángulos, materiales PBR metallic-roughness embebidos.
- **Nodos obligatorios**:
  - `Lander_Intact`: Módulo espacial íntegro con patas de aterrizaje posadas en `y = 0`.
  - `Lander_Destroyed`: Geometría de impacto/escombros mostrada tras colisión (`> 2,0 m/s`) o pérdida de señal.
  - `Thruster_Flame`: Cono emisivo bajo la tobera (`y ≤ 0`), visible únicamente cuando `status == descending && isThrusterActive == true`.
- **Paridad binaria**: Idéntico byte a byte con `apps/weinsolar-angular/public/models/lander.glb`.
