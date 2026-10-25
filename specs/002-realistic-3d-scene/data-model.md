# Data Model: Entorno Tridimensional Realista (WeinSolar v2)

**Feature**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md) | **Base v1**: [001 data-model](../001-planetary-lander-sunset/data-model.md)

Las entidades de la v1 (`CelestialBody`, `LanderState`, `MissionAttempt`, `SolarHourState`, `SkyOpticalProfile`, `TerrainTheme`) **no cambian de forma ni de semántica**, con una única excepción aditiva: `CelestialBody.lightingProfile`. Todo lo nuevo pertenece a la capa de presentación del dominio: son valores calculados por funciones puras y no forman parte del estado físico.

Los nombres son idénticos en ambos stacks. Angular usa archivos en kebab-case, como `scene-lighting-state.ts`; Flutter usa snake_case, como `scene_lighting_state.dart`.

---

## Entidades nuevas

### `VisualQuality` (enum)

| Valor | Etiqueta UI | Notas |
|-------|-------------|-------|
| `high` | «Alta» | Valor por defecto al abrir la app (FR-019) |
| `basic` | «Básica» | Simplifica el detalle (FR-022) |

- Vive en el estado de UI (provider o señal de página). **No se persiste** entre sesiones.

### `CameraMode` (enum)

| Valor | Cuándo |
|-------|--------|
| `lateralFollow` | Descenso, misión fallida (impacto o señal perdida) y cualquier estado con `SolarHourState.isUnlocked == false` |
| `orbit` | `SolarHourState.isUnlocked == true` (Hora Solar tras un éxito) |

### `LightingProfile` (nuevo atributo de `CelestialBody`)

| Campo | Tipo | Tierra | Marte | Luna | Titán |
|-------|------|--------|-------|------|-------|
| `sunAzimuthDeg` | double | 250 | 250 | 250 | 250 |
| `sunColorDayHex` | hex | `#FFF4E0` | `#FFE9D2` | `#FFF8EE` | `#E8B070` |
| `sunColorSunsetHex` | hex | `#FF7A2E` | `#6C93B8` (= `sunHaloHex`) | `#FFF8EE` | `#B5651D` |
| `ambientDayIntensity` | 0..1 | 0,45 | 0,40 | 0,0 | 0,70 |
| `twilightFadeDeg` | ° | 6 | 8 | 0 | 10 |
| `shadowSoftness` | 0..1 | 0,35 | 0,45 | 0,0 | 0,9 |
| `scientificReference` | string | *heredada de `SkyOpticalProfile` (FR-017)* | | | |

- El mismo azimut en los cuatro mundos significa que el ocaso cae siempre sobre el horizonte del encuadre lateral; no es una constante física.
- Los colores son valores iniciales de la investigación R4 y se calibran en la compuerta visual, siempre sin salir de RN-13.

### `SceneLightingState` (valor calculado)

| Campo | Tipo | Regla |
|-------|------|-------|
| `sunDirection` | vector3 normalizado | `(cos e·sin a, sin e, cos e·cos a)` |
| `sunColorHex` | hex | interpolación `smoothstep` entre día y ocaso, con e ∈ [0°, 20°] |
| `sunIntensity` | 0..1 | 1 si e ≥ 20°; decrece hasta 0 en e = −`twilightFadeDeg`; en la Luna es 0 de forma inmediata si e < 0° |
| `ambientSkyColorHex` | hex | color de cénit de `SkyOpticalProfile` interpolado por e |
| `ambientGroundColorHex` | hex | `TerrainTheme.primarySurfaceHex` |
| `ambientIntensity` | 0..1 | `ambientDayIntensity` × factor crepuscular |
| `castsShadows` | bool | `e > 0°` |
| `shadowSoftness` | 0..1 | se copia de `LightingProfile` |
| `expectedShadowLengthRatio` | double | `1 / tan(e)` si e > 0; `null` en otro caso |

- Se calcula con `ComputeSceneLightingUseCase.execute(world, solarElevationDeg)`.
- Durante el descenso se usa `e = SolarHourState.defaultInitialElevationDeg` (65°).

### `TerrainLayout` (valor calculado, determinista)

| Campo | Tipo | Regla |
|-------|------|-------|
| `worldId` | `CelestialBodyId` | |
| `sizeMeters` | double | 400 |
| `resolution` | int | 192 (`high`) o 64 (`basic`) |
| `padRadiusMeters` | double | 6,0 (≥ 2 × radio de las patas de la nave) |
| `heights` | lista de double (resolution²) | ruido determinista con semilla por mundo; **0,0 exacto** en la plataforma; transición suave entre `padRadius` y `padRadius + 4 m` |
| `features` | lista de `TerrainFeature` | rocas, cráteres, dunas o crestas de hielo según el mundo; ninguna dentro de `padRadius + 2 m` |

- Se calcula con `GenerateTerrainLayoutUseCase.execute(world, quality)`. Son funciones puras, sin `Random` global; la semilla sale de `worldId`.

### `TerrainFeature`

| Campo | Tipo |
|-------|------|
| `kind` | `rock` \| `crater` \| `dune` \| `iceRidge` \| `vegetation` |
| `x`, `z` | double (m, centro de la plataforma = 0,0) |
| `scale` | double |
| `rotationDeg` | double |

### `SceneDescriptor` (mapper de UI, no es dominio)

Es el contrato que recibe el componente o widget de escena (ver [contracts/scene-rendering-contract.md](contracts/scene-rendering-contract.md)):
`{ world, landerVisual, lighting: SceneLightingState, terrain: TerrainLayout, cameraMode, cameraAzimuthDeg, quality: QualitySettings }`.

- `landerVisual`: `{ altitudeMeters, status: LanderStatus, isThrusterActive }`, en solo lectura y derivado de `LanderState`.
- `QualitySettings`: tabla R6 (`shadowMapSize`, `shadowCascades`, `terrainResolution`, `featureDensity`, `useImageBasedLighting`, `maxPixelRatio`).

---

## Transiciones de estado relevantes

```text
             selectWorld                    contacto ≤ 2,0 m/s
[Selección] ───────────▶ [Descenso] ─────────────────────────▶ [Aterrizada]
                         cameraMode=lateralFollow              cameraMode=orbit (SolarHour.isUnlocked)
                              │ contacto > 2,0 m/s / techo
                              ▼
                         [Destruida / Señal perdida]
                         cameraMode=lateralFollow (sin giro)

VisualQuality: high ⇄ basic   (en cualquier estado; no altera LanderState, MissionAttempt ni SolarHourState)
```

---

## Reglas de negocio nuevas (continúan la numeración de la v1)

- **RN-09 (Invariancia de presentación)**: para cualquier secuencia de entradas de pilotaje, la serie de `LanderState` y el `MissionAttempt` final son idénticos con independencia de `VisualQuality`, `CameraMode`, de los cambios de calidad a mitad del descenso y de la carga de assets (FR-001, FR-002, SC-001, SC-010).
- **RN-10 (Plataforma plana)**: en todo `TerrainLayout`, `height(x,z) == 0.0` para `√(x²+z²) ≤ padRadiusMeters`, y ninguna `TerrainFeature` cae a menos de `padRadius + 2 m` del centro (FR-012).
- **RN-11 (Modo de cámara)**: `cameraMode == orbit` ⇔ `SolarHourState.isUnlocked`. Una entrada de giro en `lateralFollow` se ignora (FR-010).
- **RN-12 (Geometría de sombras)**: `castsShadows == (e > 0°)`. Con e > 0, `expectedShadowLengthRatio == 1/tan(e)` con un error ≤ 1e-6. La longitud es monótona creciente al bajar e (FR-013, FR-014, SC-004).
- **RN-13 (Aislamiento cromático de escena)**: ningún color de `LightingProfile`, `SceneLightingState`, `TerrainTheme` ni `SkyOpticalProfile` puede ser exactamente uno de los cuatro códigos Weincode. Además:
  - debe quedar a una distancia euclídea RGB ≥ 48 de `#18084D`, `#5236FF` y `#A599FF`;
  - debe quedar a una distancia ≥ 16 de `#FFFFFF`. Este umbral es menor porque la luz solar real es casi blanca: el Principio I prevalece y exige luz física, pero el blanco puro de la marca queda excluido.

  Amplía RN-08 (Principio III, FR-006).
- **RN-14 (Fidelidad de tintes)**: el tinte del ocaso sobre la nave proviene solo de `LightingProfile` y `SkyOpticalProfile`, con su `scientificReference`. La Luna no tiene luz ambiental (`ambientDayIntensity == 0`) y su `twilightFadeDeg == 0` (FR-015, FR-016, FR-017).
- **RN-15 (Paridad de calidad)**: entre `high` y `basic`, `SceneLightingState` es idéntico y solo cambian `QualitySettings` y `TerrainLayout.resolution` / `features.length`. La plataforma (RN-10) se mantiene en ambos (FR-022).
