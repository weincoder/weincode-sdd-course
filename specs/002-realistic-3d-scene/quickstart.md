# Quickstart: Entorno Tridimensional Realista (WeinSolar v2)

**Plan**: [plan.md](plan.md) | **Research**: [research.md](research.md)

## 0. Prerrequisitos

```bash
# Flutter: flutter_scene ^0.24.3 exige Flutter >= 3.47 stable (hoy está instalado 3.44.2)
flutter upgrade            # objetivo: 3.47.1 o superior, canal stable
flutter --version

# Angular: se mantiene Angular 19.2 (angular-three 3.7.2 exige @angular/core >=19 <20)
node --version             # LTS compatible con Angular 19
```

## 1. Paso previo a tocar código: congelar las trayectorias de referencia de la v1

Antes de modificar nada, se generan los fixtures de paridad (R8 punto 4, SC-001) con los casos de uso actuales:

```bash
# Flutter: con WRITE_FIXTURES=true escribe test/fixtures/reference_trajectories.json; sin el flag, compara
cd apps/weinsolar-flutter && flutter test test/domain/reference_trajectories_test.dart --dart-define=WRITE_FIXTURES=true
# Angular: Karma no escribe en disco, así que en el commit v1 (46497dc) el spec, en modo «print»,
# vuelca el JSON por consola y ese JSON se guarda en src/app/domain/usecase/__fixtures__/.
# Cada stack se compara con SU PROPIA v1 (no se exige igualdad numérica entre Angular y Flutter).
cd apps/weinsolar-angular && npm test -- --watch=false --include='**/reference-trajectories.spec.ts'
```

## 2. Instalación de dependencias (solicitadas explícitamente por el usuario)

```bash
# Flutter
cd apps/weinsolar-flutter
flutter pub add flutter_scene:^0.24.3
dart run flutter_scene:init          # genera hook/build.dart y registra flutter_scene_generated/
# Activar Flutter GPU de forma permanente:
#   ios/Runner/Info.plist        -> <key>FLTEnableFlutterGPU</key><true/>
#   (Android/macOS si se añaden)  -> meta-data EnableFlutterGPU / Info.plist
#   Web: no hace falta nada (backend WebGL2)

# Angular
cd apps/weinsolar-angular
npm install angular-three@3.7.2 three@0.172.0 ngxtension@^7.3.1
npm install -D @types/three@0.172.0
# angular.json -> "assets": [{ "glob": "**/*", "input": "public" }]
```

## 3. Ejecutar

```bash
# Flutter (en desarrollo con Flutter GPU)
cd apps/weinsolar-flutter && flutter run --enable-flutter-gpu        # iOS / macOS
cd apps/weinsolar-flutter && flutter run -d chrome                   # Web (WebGL2)

# Angular
cd apps/weinsolar-angular && npm start
```

## 4. Tests First (orden TDD)

1. Dominio: `compute-scene-lighting`, `generate-terrain-layout` y `resolve-camera-mode` (RN-10 a RN-15).
2. Mapper y adaptador: `lightingProfile` presente en los 4 mundos; error si falta; RN-13 sobre todos los colores.
3. UI pura: `SceneDescriptorMapper` (tabla de calidad R6, modo de cámara y estados de la nave).
4. Página: placeholder de escena; cambio de calidad a mitad del descenso → mismo resultado que el fixture (SC-010).
5. Regresión: trayectorias de referencia de la v1, idénticas (SC-001).

```bash
cd apps/weinsolar-flutter && flutter analyze && flutter test
cd apps/weinsolar-angular && npm test -- --watch=false && npm run build
```

## 5. Compuertas automáticas (grep)

```bash
# Sin física de motor (Restricciones del Producto)
! grep -rnE "flutter_scene/physics|flutter_scene_rapier|flutter_scene/audio" apps/weinsolar-flutter/lib
# La escena no importa casos de uso de simulación (RN-09)
! grep -rnE "simulate[-_]descent|evaluate[-_]solar" apps/weinsolar-flutter/lib/ui/widgets/scene3d apps/weinsolar-angular/src/app/UI/ds/organisms/planetary-scene-3d
# Sin recursos remotos (Principio IV)
! grep -rnE "https?://" apps/weinsolar-flutter/lib/ui/widgets/scene3d apps/weinsolar-angular/src/app/UI/ds/organisms/planetary-scene-3d
# Sin angular-three-soba ni three-stdlib (R2)
! grep -nE "angular-three-soba|three-stdlib" apps/weinsolar-angular/package.json
# El mismo GLB en los dos stacks (R3) — SHA-256 esperado: e259904949ee4c6ff34068bd700b6726f994703bb963920f47f02f69e0bd7a5b
shasum -a 256 apps/weinsolar-flutter/assets/models/lander.glb apps/weinsolar-angular/public/models/lander.glb
```

## 6. Compuerta de Verificación Visual (manual, en cada stack)

| # | Paso | Esperado | Criterio |
|---|------|----------|----------|
| V1 | Elegir cada mundo y descender | Nave con volumen; relieve característico; la sombra de la nave converge con su base al tocar | FR-007 a FR-009 |
| V2 | Intentar arrastrar o girar durante el descenso | La cámara no se mueve | FR-010 |
| V3 | Aterrizar con éxito y girar 360° | La nave queda centrada y la cabina inmóvil | FR-005, FR-010 |
| V4 | Hora Solar a 45° y a 10° con el poste de 2 m | Sombra de ≈ 2 m y ≈ 11,3 m (±10 %) | SC-004 |
| V5 | Ocaso en Marte | Reflejo azulado en las caras orientadas al sol; terreno ocre | FR-016 |
| V6 | Luna: sol cruzando el horizonte | Sombras nítidas y negras; apagado abrupto | FR-015, FR-018 |
| V7 | Titán | Sombras difusas; tinte ámbar | FR-015, FR-016 |
| V8 | Cambiar Alta ⇄ Básica a mitad del descenso | Cambio en < 2 s; mismo resultado de aterrizaje | FR-019, SC-010 |
| V9 | Muestreo de colores de la escena | Ningún color incumple RN-13; HUD solo con los 4 códigos | FR-006, SC-007 |
| V10 | Rendimiento | ≥ 30 imágenes por segundo: Alta en un portátil de gama media, Básica en un móvil de gama media | SC-005 |
| V11 | Modo avión tras abrir | Ciclo completo sin red | SC-009 |
| V12 | Tiempo de carga tras elegir mundo | < 5 s | SC-006 |
