# Phase 1: Domain Gateways & UI Contracts — WeinSolar v1

**Feature**: `001-planetary-lander-sunset`  
**Date**: 2026-10-18

Siguiendo **Principio IV (Autonomía en Cliente y Cero Dependencia Externa)** y las guías de Clean Architecture de `.github/instructions/angular-instructions.md` y `.github/instructions/flutter-instructions.md`, no existen contratos HTTP remotos. Los contratos del sistema son:
1. **Gateways Abstractos del Dominio** (Puertos inyectados en los Casos de Uso e implementados por Adaptadores Locales en `infraestructure/` o `infrastructure/`).
2. **Contratos de Casos de Uso** (Consumidos por la UI en Angular y por los `ChangeNotifier` Providers en Flutter).
3. **Contrato Visual de Cabina Weincode y Escena 3D**.

---

## 1. Contrato de Gateway: `CelestialBodyGateway`

Provee el catálogo inmutable y científicamente validado de los 4 cuerpos celestes.

### Firma en Angular (`src/app/domain/models/celestial-body/gateway/celestial-body-gateway.ts`)
```typescript
import { Observable } from 'rxjs';
import { CelestialBody, CelestialBodyId } from '../celestial-body';

export abstract class CelestialBodyGateway {
  abstract getAll(): Observable<CelestialBody[]>;
  abstract getById(id: CelestialBodyId): Observable<CelestialBody>;
}
```

### Firma en Flutter (`lib/domain/models/celestial_body/gateway/celestial_body_gateway.dart`)
```dart
import '../celestial_body.dart';

abstract class CelestialBodyGateway {
  Future<List<CelestialBody>> getAll();
  Future<CelestialBody> getById(CelestialBodyId id);
}
```

---

## 2. Casos de Uso del Dominio (Contratos de Negocio)

| Caso de Uso | Archivo Angular (`domain/usecase/`) | Archivo Flutter (`domain/usecase/`) | Responsabilidad Única |
| :--- | :--- | :--- | :--- |
| **Catálogo de Mundos** | `get-celestial-bodies.use-case.ts` (`GetCelestialBodiesUseCase`) | `get_celestial_bodies_use_case.dart` (`GetCelestialBodiesUseCase`) | Obtiene los 4 mundos desde `CelestialBodyGateway` y valida invariantes astrofísicas (**FR-001**, **FR-002**, **RN-01**). |
| **Física de Descenso** | `simulate-descent-step.use-case.ts` (`SimulateDescentStepUseCase`) | `simulate_descent_step_use_case.dart` (`SimulateDescentStepUseCase`) | Calcula un tick cinemático puro $(\Delta t_{\text{real}}, \text{world}, \text{state}) \to (\text{nextState}, \text{attempt})$ aplicando gravedad, resistencia cuadrática, empuje, consumo, escala temporal, techo $1.5 \times h_0$ y evaluación de aterrizaje $\le 2.0\text{ m/s}$ (**FR-003..013**, **FR-024..026**). |
| **Óptica de Hora Solar** | `evaluate-solar-hour.use-case.ts` (`EvaluateSolarHourUseCase`) | `evaluate_solar_hour_use_case.dart` (`EvaluateSolarHourUseCase`) | Verifica que `attempt.outcome === 'success'` (**RN-06**) y calcula los colores del cielo, halo solar, dureza de sombras e intensidad ambiental para `solarElevationDeg` y `cameraAzimuthDeg` (**FR-014..016**, **FR-029..030**). |

---

## 3. Contrato Visual de Cabina (HUD Weincode) y Controles

### 3.1 Restricción de Paleta en Cabina (`RN-08` / Principio III)
Todo componente dentro de `UI/ds/` (Angular) o `ui/widgets/` (Flutter) que represente cabina, telemetría, selectores o modales de resultado **MUST** utilizar únicamente estos tokens CSS / `Color`:

| Token Semántico | Código Hex | Uso Obligatorio en Cabina |
| :--- | :---: | :--- |
| `weincodeIndigoDeep` | `#18084D` | Fondo de paneles de cabina, tarjetas de selección y modales |
| `weincodeElectricViolet` | `#5236FF` | Botón de propulsor activo, bordes principales, barra de progreso y controles interactivos |
| `weincodeSoftLavender` | `#A599FF` | Etiquetas secundarias, bordes sutiles, indicadores de estado informativo / alerta sin introducir colores fuera de paleta |
| `weincodePureWhite` | `#FFFFFF` | Valores numéricos de telemetría, títulos principales e iconos de alto contraste |

> **Regla de verificación visual y de test**: En la alerta de velocidad peligrosa (`|v_y| > 2.0 m/s`, **FR-020**) o proximidad al techo (**FR-019**), el estado de peligro se representa mediante contraste, parpadeo/borde `#5236FF` sobre `#18084D`, insignia textual explícita (`"PELIGRO (> 2,0 m/s)"` vs `"VELOCIDAD SEGURA (≤ 2,0 m/s)"`) e iconografía en `#FFFFFF` / `#A599FF`, **sin introducir rojo/verde en el HUD**, cumpliendo al 100% la literalidad de **FR-021** y el **Principio III**.

### 3.2 Entradas de Usuario Requeridas
1. **Propulsor Principal (`FR-022`)**:
   - Teclado: mantener pulsada `Space` o `ArrowUp` activa `isThrusterActive = true`; soltar la tecla la pasa a `false`.
   - Pantalla táctil / ratón: `pointerdown` / `GestureDetector.onTapDown` activa `isThrusterActive = true`; `pointerup` / `pointerleave` / `onTapUp` / `onTapCancel` la pasa a `false`.
2. **Pausa Automática por Foco (`Edge Case`)**:
   - Pérdida de foco de ventana (`visibilitychange` / `blur` en Web; `AppLifecycleState.paused` / `inactive` en Flutter) pausa el acumulador de $\Delta t$ para evitar saltos cinemáticos al regresar.
3. **Controles Post-Aterrizaje Exitoso (`FR-014`, `FR-029`)**:
   - Deslizador continuo **"Hora Solar"**: rango `[-10°, 90°]`, valor inicial `65°`.
   - Control / arrastre horizontal **"Giro de Cámara"**: rango `[0°, 360°)`.
4. **Acciones de Ciclo (`FR-017`, `FR-018`)**:
   - En descenso: botón **"Reiniciar"** (reinicia condiciones iniciales del mundo actual).
   - En resultado final (éxito o fallo): botones **"Reintentar"** y **"Cambiar mundo"**.
