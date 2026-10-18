# Contexto Técnico Local — WeinSolar Flutter (`apps/weinsolar-flutter`)

## Stack Declarado (Inmutable salvo enmienda constitucional)
- **Framework y Lenguaje**: Flutter 3.x + Dart 3.x (Material 3, null-safety estricto).
- **Gestión de Estado**: Estado local limpio basado en `ChangeNotifier` dentro de `lib/config/providers/` (respetando la regla "Cero Alucinaciones de Paquetes" de `.github/instructions/flutter-instructions.md`).
- **Física y Renderizado 3D a 60 FPS**: Cinemática 100 % en Dart puro dentro de `lib/domain/usecase/` (cero librerías externas de física). Escena 3D renderizada con `CustomPainter` + proyecciones 3D en perspectiva y bucle de animación a 60 FPS mediante `SingleTickerProviderStateMixin` (`Ticker`), con pausa automática ante cambios de `AppLifecycleState`.
- **Arquitectura e Inyección**: Clean Architecture estricta (`lib/domain/`, `lib/infrastructure/`, `lib/ui/`, `lib/config/`). `domain` es 100 % Dart puro (prohibido importar `package:flutter/material.dart`). Todas las dependencias se inyectan por constructor.
- **Identidad Cromática y Autonomía**: Cabina y telemetría restringidas a `0xFF18084D`, `0xFF5236FF`, `0xFFA599FF` y `0xFFFFFFFF` sin contaminar el `CustomPainter` de la escena 3D. Ejecución 100 % offline con `CelestialBodyLocalAdapter`.
- **Idioma**: Código (clases, métodos, variables, archivos) en inglés; textos visibles en la UI en español.
