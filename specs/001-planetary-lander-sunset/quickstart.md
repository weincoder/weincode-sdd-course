# Phase 1: Quickstart & Verification Guide — WeinSolar v1

**Feature**: `001-planetary-lander-sunset`  
**Date**: 2026-10-18

---

## 1. Ubicación de las dos implementaciones

| Plataforma | Directorio del Proyecto | Instrucciones Obligatorias de Arquitectura |
| :--- | :--- | :--- |
| **🅰️ Angular (Web)** | `apps/weinsolar-angular/` | `.github/instructions/angular-instructions.md` + `apps/weinsolar-angular/AGENTS.md` |
| **💙 Flutter (Multiplataforma)** | `apps/weinsolar-flutter/` | `.github/instructions/flutter-instructions.md` + `apps/weinsolar-flutter/AGENTS.md` |

---

## 2. Flujo de Ejecución y Tests First (TDD)

### 2.1 Angular (`apps/weinsolar-angular`)

```bash
# 1. Instalar dependencias locales (una sola vez)
npm --prefix apps/weinsolar-angular install

# 2. Ejecutar el Plan de Pruebas Unitarias (Tests First: RN y CA antes de pintar UI)
npm --prefix apps/weinsolar-angular test -- --watch=false

# 3. Levantar servidor local de desarrollo (100% offline-capable tras abrir)
npm --prefix apps/weinsolar-angular start
```

### 2.2 Flutter (`apps/weinsolar-flutter`)

```bash
# 1. Resolver paquetes del SDK de Flutter
flutter pub get --directory=apps/weinsolar-flutter

# 2. Ejecutar el Plan de Pruebas Unitarias en Dart (Tests First: RN de descenso, gravedad y óptica)
flutter test apps/weinsolar-flutter/test

# 3. Análisis estático sin errores ni warnings
dart analyze apps/weinsolar-flutter

# 4. Ejecutar aplicación a 60 FPS (Chrome, macOS, iOS o Android)
flutter run --project-root=apps/weinsolar-flutter
```

---

## 3. Lista de Verificación Constitucional (Compuerta Visual y Funcional)

1. **Constantes Planetarias (`Principio I`, `SC-005`)**:
   - Tierra ($9.81\text{ m/s}^2$, $\rho = 1.225\text{ kg/m}^3$), Marte ($3.71\text{ m/s}^2$, $\rho = 0.020\text{ kg/m}^3$), Luna ($1.62\text{ m/s}^2$, $\rho = 0$), Titán ($1.352\text{ m/s}^2$, $\rho = 5.3\text{ kg/m}^3$).
2. **Umbral Estructural y Techo (`Principio II`, `FR-009`, `FR-010`, `FR-024`)**:
   - Contacto a $2.0\text{ m/s}$ $\to$ **Aterrizaje exitoso** y desbloqueo de **Hora Solar**.
   - Contacto a $2.1\text{ m/s}$ $\to$ **Misión fallida**, sonda destruida y **Hora Solar bloqueada**.
   - Altitud $> 1.5 \times h_0$ ($750\text{ m}$) $\to$ **Misión fallida – señal perdida** y **Hora Solar bloqueada**.
3. **Identidad Cromática Weincode (`Principio III`, `FR-021`)**:
   - HUD usa exclusivamente `#18084D`, `#5236FF`, `#A599FF` y `#FFFFFF`.
   - Escena 3D (cielo, terreno, sonda e iluminación) libre de contaminación morada/violeta.
4. **Autonomía Offline (`Principio IV`, `FR-023`, `SC-009`)**:
   - Desconectar red con la app abierta y completar selección $\to$ descenso $\to$ aterrizaje $\to$ Hora Solar $\to$ reinicio sin errores.
