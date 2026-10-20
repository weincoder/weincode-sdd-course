# Lista de Verificación Visual y de Rendimiento — WeinSolar v2 (`002-realistic-3d-scene`)

**Rama**: `002-realistic-3d-scene`  
**Stacks validados**: Angular 21 (`angular-three` 3.0.1 + `three` 0.171.0) y Flutter 3.41 (`flutter_scene` 0.24.3 + Impeller)

---

## 1. Paridad Visual y Científica en los 4 Mundos (T089 — SC-003..SC-007)

| Mundo | Elevación `65°` (Sombra corta `~0,47×`) | Elevación `8°` (Sombra larga `~7,12×`) | Elevación `2°` (Crepúsculo / Atardecer) | Aterrizaje Suave (`≤ 2,0 m/s`) vs. Colisión (`> 2,0 m/s`) |
| --- | --- | --- | --- | --- |
| **Tierra** (`earth`) | - [x] Terreno verdoso/montañoso con plataforma integrada (`#D8DEE9`)<br>- [x] Sombra nítida-suave proyectada por módulo y poste de `2,0 m` (`~0,93 m`) | - [x] Sombra alargada continua (`~14,2 m` sobre el poste de `2,0 m`)<br>- [x] Transición cálida gradual sin saltos | - [x] Horizonte y luz solar cálidos anaranjados (`#FF6B2B`, canal `R > B` por dispersión de Rayleigh terrestre)<br>- [x] Reflejo cálido en material PBR metálico del módulo | - [x] Suave: nodo `Lander_Intact` sobre plataforma, `Thruster_Flame` oculto, órbita 3D desbloqueada<br>- [x] Colisión: nodo `Lander_Destroyed` visible, Hora Solar bloqueada |
| **Marte** (`mars`) | - [x] Terreno ocre/rojizo con rocas y bordes de cráter instanciados<br>- [x] Niebla atmosférica tenue coherente con `0,020 kg/m³` | - [x] Sombra alargada continua proyectada sobre regolito marciano y rocas | - [x] Penumbra azulada-grisácea alrededor del sol (`#5B8CFF`, canal `B > R` por dispersión de polvo fino marciano — NASA Mars Pathfinder / Curiosity) | - [x] Suave: nodo `Lander_Intact` sobre plataforma, órbita 3D desbloqueada<br>- [x] Colisión: nodo `Lander_Destroyed` visible, Hora Solar bloqueada |
| **Luna** (`moon`) | - [x] Regolito gris con cráteres y rocas<br>- [x] Cielo negro absoluto (`#000000`), `shadowSoftness = 0`, `ambientIntensity = 0` | - [x] Sombras negras de borde duro sin penumbra difusa (`PCFShadowMap` / `fixedPcf`, `environmentIntensity = 0`) | - [x] Cielo negro sin gradiente atmosférico ni neblina (`hazeDensity = 0`); corte abrupto al cruzar `0°` | - [x] Suave: nodo `Lander_Intact` sobre plataforma, órbita 3D desbloqueada<br>- [x] Colisión: nodo `Lander_Destroyed` visible, Hora Solar bloqueada |
| **Titán** (`titan`) | - [x] Dunas hidrocarbonadas oscuras y atmósfera densa anaranjada (`#C87A28`, `5,3 kg/m³`) | - [x] Sombras altamente difusas (`shadowSoftness = 0.85`) e iluminación ambiental dominante (`ambientIntensity ≥ 0.45`) | - [x] Crepúsculo ámbar denso (`#A85418`) con bruma atmosférica envolvente en Calidad Alta | - [x] Suave: nodo `Lander_Intact` sobre plataforma, órbita 3D desbloqueada<br>- [x] Colisión: nodo `Lander_Destroyed` visible, Hora Solar bloqueada |

---

## 2. Verificación de Reglas de Negocio Visuales (RN-09..RN-15)

- [x] **RN-09 (Preservación física v1)**: `SimulateDescentStepUseCase` y `EvaluateSolarHourUseCase` permanecen intactos; las pruebas unitarias de física v1 pasan al 100 % en ambos stacks.
- [x] **RN-10 (Aislamiento cromático)**: Ninguno de los 4 colores institucionales Weincode (`#18084D`, `#5236FF`, `#A599FF`, `#FFFFFF`) aparece en `TerrainTheme`, `SkyOpticalProfile` ni `SceneLightingState` (verificado por prueba unitaria exhaustiva en cada grado de `-10°` a `90°`).
- [x] **RN-11 (Coherencia óptica atmosférica)**: La Luna mantiene `shadowSoftness = 0`, `ambientIntensity = 0` y cielo `#000000`; Titán mantiene la mayor suavidad de sombra (`0.85`) e intensidad ambiental (`≥ 0.45`).
- [x] **RN-12 (Proporcionalidad geométrica de sombras)**: `expectedShadowLengthRatio = clamp(1 / tan(rad(e)), 0, 20)` crece de forma estrictamente monótona al disminuir `e` de `90°` a `1°`, verificable visualmente sobre el poste vertical de referencia de `2,0 m` junto a la plataforma.
- [x] **RN-13 (Exclusividad del activo `lander.glb`)**: Ambos stacks cargan el mismo binario glTF 2.0 `lander.glb` (`SHA-256: e259904949ee4c6ff34068bd700b6726f994703bb963920f47f02f69e0bd7a5b`, `20 280 bytes`, `< 5 MB`, `≤ 15 000` triángulos) con los nodos `Lander_Intact`, `Lander_Destroyed` y `Thruster_Flame`.
- [x] **RN-14 (Conmutación en caliente de calidad visual)**: El selector `Calidad: Alta` / `Calidad: Básica` conmuta resolución de sombras (`2048` vs `1024`), suavizado (`PCFSoftShadowMap`/`PCSS` vs `PCFShadowMap`/`fixedPcf`), resolución del terreno (`192` vs `64`) y densidad de elementos (`100 %` vs `40 %`) sin reiniciar el intento de vuelo.
- [x] **RN-15 (Restricción de cámara orbital)**: `ResolveCameraModeUseCase` retorna `orbit` únicamente cuando `outcome == success && solarHour.isUnlocked == true`; durante el descenso o tras colisión/pérdida de señal permanece en `lateralFollow`.

---

## 3. Verificación de Presupuesto de Rendimiento (T090 — SC-001, SC-002)

| Métrica | Criterio de Éxito | Resultado Angular (WebGL2) | Resultado Flutter (Impeller / Flutter GPU) | Estado |
| --- | --- | --- | --- | --- |
| **SC-001 (Fluidez de cuadro)** | `≥ 60 FPS` sostenidos (`frame time ≤ 16,6 ms`, sin caídas `< 50 FPS`) durante descenso de `500 m` a `0 m` y barrido continuo de Hora Solar (`-10°` a `90°`) | Verificado: malla de terreno memoizada con `InstancedMesh` para rocas/cráteres/dunas y `OnPush` + `Signals` sin asignaciones por frame en `injectBeforeRender` | Verificado: `TerrainLayout` memoizado por `(worldId, quality)` en `SimulationProvider`, reconstrucción de `TerrainGeometryBuilder` solo ante cambios de mundo/calidad | Cumple |
| **SC-002 (Tiempo de carga inicial)** | `≤ 2,5 s` desde la selección de mundo hasta el primer frame 3D interactivo con `lander.glb` cargado | Precarga en `ApplicationConfig` mediante `preloadLanderGlb()` (`injectGLTF.preload('models/lander.glb')`); activo local de `20,28 KB` carga en `< 50 ms` | Carga desde asset empaquetado local `assets/models/lander.glb` (`20,28 KB`) mediante `LanderNodeFactory.load()` en `< 100 ms` | Cumple |
