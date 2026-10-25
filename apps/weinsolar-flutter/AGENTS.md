# Contexto Técnico Local — WeinSolar Flutter (`apps/weinsolar-flutter`)

## Stack Declarado (Inmutable salvo enmienda constitucional)
- **Framework y Lenguaje**: Flutter ≥ 3.47.1 stable + Dart 3.x (Material 3, null-safety estricto).
- **Gestión de Estado**: Estado local limpio basado en `ChangeNotifier` dentro de `lib/config/providers/` (respetando la regla "Cero Alucinaciones de Paquetes" de `.github/instructions/flutter-instructions.md`).
- **Física y Renderizado 3D a 60 FPS**: Cinemática 100 % en Dart puro dentro de `lib/domain/usecase/` (cero librerías externas de física). Escena 3D renderizada con `flutter_scene: ^0.24.3` sobre Impeller + Flutter GPU (`FLTEnableFlutterGPU` activo) y bucle de animación a 60 FPS mediante `SingleTickerProviderStateMixin` (`Ticker`), con pausa automática ante cambios de `AppLifecycleState`.
- **Prohibiciones de Paquetes / Módulos**: Prohibido importar `package:flutter_scene/physics.dart`, `package:flutter_scene/audio.dart` o añadir `flutter_scene_rapier`.
- **Arquitectura e Inyección**: Clean Architecture estricta (`lib/domain/`, `lib/infrastructure/`, `lib/ui/`, `lib/config/`). `domain` es 100 % Dart puro (prohibido importar `package:flutter/material.dart`, `flutter_scene` o `vector_math`). Todas las dependencias se inyectan por constructor.
- **Identidad Cromática y Autonomía**: Cabina y telemetría restringidas a `0xFF18084D`, `0xFF5236FF`, `0xFFA599FF` y `0xFFFFFFFF` sin contaminar la escena 3D (RN-13). Ejecución 100 % offline con `CelestialBodyLocalAdapter` y `assets/models/lander.glb` local.
- **Idioma**: Código (clases, métodos, variables, archivos) en inglés; textos visibles en la UI en español.
