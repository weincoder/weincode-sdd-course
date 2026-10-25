# Contrato: Dominio de presentación 3D y escena (WeinSolar v2)

**Feature**: [../spec.md](../spec.md) | **Data model**: [../data-model.md](../data-model.md) | **Contratos v1**: [001 domain-and-ui-contracts](../../001-planetary-lander-sunset/contracts/domain-and-ui-contracts.md)

Los contratos de la v1 (`CelestialBodyGateway`, `GetCelestialBodiesUseCase`, `SimulateDescentStepUseCase`, `EvaluateSolarHourUseCase`) **no cambian**. Este documento añade los casos de uso puros de presentación y el contrato de entrada y salida del componente o widget de escena.

---

## 1. Casos de uso nuevos (dominio, puros y síncronos)

### Angular (`src/app/domain/usecase/`)

```typescript
// compute-scene-lighting.use-case.ts
@Injectable({ providedIn: 'root' })
export class ComputeSceneLightingUseCase {
  execute(world: CelestialBody, solarElevationDeg: number): SceneLightingState;
}

// generate-terrain-layout.use-case.ts
@Injectable({ providedIn: 'root' })
export class GenerateTerrainLayoutUseCase {
  execute(world: CelestialBody, quality: VisualQuality): TerrainLayout; // determinista, memoizable por (worldId, quality)
}

// resolve-camera-mode.use-case.ts
@Injectable({ providedIn: 'root' })
export class ResolveCameraModeUseCase {
  execute(solarHour: SolarHourState): CameraMode;
}
```

### Flutter (`lib/domain/usecase/`)

```dart
class ComputeSceneLightingUseCase {
  SceneLightingState execute(CelestialBody world, double solarElevationDeg);
}

class GenerateTerrainLayoutUseCase {
  TerrainLayout execute(CelestialBody world, VisualQuality quality);
}

class ResolveCameraModeUseCase {
  CameraMode execute(SolarHourState solarHour);
}
```

**Pre y postcondiciones**:
- `solarElevationDeg` se acota a `[SolarHourState.minElevationDeg, maxElevationDeg]` = `[-10°, 90°]`.
- Ningún caso de uso nuevo lee ni modifica `LanderState` ni `MissionAttempt` (RN-09).
- Dos llamadas con los mismos argumentos devuelven valores iguales campo a campo.
- Cumplen RN-10 a RN-15 de [data-model.md](../data-model.md).

**Ampliación del gateway (aditiva)**: el `CelestialBodyLocalAdapter` y su mapper incluyen `lightingProfile` en cada mundo. Si falta ese campo, el mapper lanza un error de dominio; no hay valores por defecto silenciosos (Principio I).

---

## 2. Estado de UI (orquestación)

| Stack | Dónde | Estado nuevo | Acciones nuevas |
|-------|-------|--------------|-----------------|
| Angular | `UI/pages/simulator/simulator.component.ts` (signals) | `visualQuality = signal<VisualQuality>('high')`; `sceneLighting = computed(...)`; `terrainLayout = computed(...)`; `cameraMode = computed(...)` | `setVisualQuality(q)` |
| Flutter | `config/providers/simulation_provider.dart` (`ChangeNotifier`) | getters `visualQuality`, `sceneLighting`, `terrainLayout`, `cameraMode` | `setVisualQuality(VisualQuality q)` |

- `setVisualQuality` **no** llama a `SimulateDescentStepUseCase`, **no** reinicia el `Ticker`/RAF y **no** modifica `_landerState`, `_missionAttempt` ni `_solarHourState` (RN-09, SC-010).
- El ya existente `updateCameraAzimuth` se ignora si `cameraMode != orbit` (RN-11).

---

## 3. Contrato del componente o widget de escena

### Angular — `PlanetaryScene3dComponent` (`UI/ds/organisms/planetary-scene-3d/`)

Es presentacional (Design System): no inyecta casos de uso.

```typescript
readonly descriptor = input.required<SceneDescriptor>();
readonly cameraAzimuthChanged = output<number>();  // solo se emite en modo orbit
readonly sceneReady = output<void>();              // GLB y terreno listos (SC-006)
```

Por dentro:
- `<ngt-canvas [sceneGraph]="PlanetarySceneGraphComponent" [shadows]="true">`.
- Hijos: `LanderModelComponent`, `TerrainMeshComponent`, `SunLightComponent`, `SceneCameraRigComponent` (con `OrbitControls` registrado vía `extend`).

### Flutter — `PlanetarySceneView` (`lib/ui/widgets/scene3d/`)

```dart
class PlanetarySceneView extends StatefulWidget {
  final SceneDescriptor descriptor;
  final ValueChanged<double>? onCameraAzimuthChanged; // solo se invoca en modo orbit
  final VoidCallback? onSceneReady;
}
```

Por dentro:
- `SceneView` de `flutter_scene`.
- Una `DirectionalLight` (vía `DirectionalLightComponent`) cuya dirección e intensidad salen de `descriptor.lighting`; el valor viene, en última instancia, del slider Hora Solar.
- La nave se carga con `loadScene('assets/models/lander.glb')`.
- El terreno se construye con `MeshGeometry`/`GeometryBuilder` a partir de `descriptor.terrain`.
- `GestureDetector` controla el modo orbit.

### Invariantes del contrato (ambos stacks)

1. **Solo lectura**: la escena nunca escribe estado físico; su única salida son eventos de cámara y `sceneReady`.
2. **Cabina superpuesta**: el HUD Weincode se pinta **fuera** del lienzo 3D, en una capa hermana superior (`simulator-shell` / `Stack`), sin transformarse con la cámara (FR-005).
3. **Paleta**: ningún material, luz ni color de fondo de la escena usa un color que incumpla RN-13.
4. **Estados de la nave**: `descending` muestra `Lander_Intact` (con `Thruster_Flame` si `isThrusterActive`); `landed` muestra `Lander_Intact`; `crashed` y `lostSignal` muestran `Lander_Destroyed` (con `lostSignal` la nave puede quedar fuera de encuadre).
5. **Sombras**: la nave y los `TerrainFeature` proyectan sombras; el terreno las recibe. Con `lighting.castsShadows == false` no se renderizan sombras solares.
6. **Calidad**: un cambio de `descriptor.quality` reconstruye el terreno o los mapas de sombra en < 2 s sin reiniciar el lienzo ni recargar el GLB (FR-019).
7. **Sin red**: no hay URLs absolutas; todos los recursos son rutas locales del bundle (FR-020).
8. **Sin física de motor**: queda prohibido importar `package:flutter_scene/physics.dart`, `flutter_scene_rapier` o cualquier módulo de física de `three` o `angular-three`.

---

## 4. Selector de calidad (cabina)

| Stack | Componente | Contrato |
|-------|-----------|----------|
| Angular | `UI/ds/molecules/quality-toggle/quality-toggle.component.ts` | `value = input.required<VisualQuality>()`, `valueChange = output<VisualQuality>()`; etiquetas «Calidad: Alta / Básica» |
| Flutter | `lib/ui/widgets/quality_toggle.dart` | `QualityToggle({required VisualQuality value, required ValueChanged<VisualQuality> onChanged})` |

- Está visible en la pantalla de selección y en la cabina durante cualquier fase.
- Usa solo la paleta Weincode (Principio III).
- Es accesible por teclado y por toque.
