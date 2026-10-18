# Phase 0: Research & Decisions — WeinSolar v1 (Angular & Flutter)

**Feature**: `001-planetary-lander-sunset`  
**Date**: 2026-10-18

---

## 1. Modelo Físico y Calibración de Escenarios (Ambos Stacks)

### Decision
Usar integración cinemática explícita (semi-implícita de Euler con $\Delta t$ acotado a $\le 0.05\text{ s}$) en el bucle nativo de cada plataforma (`requestAnimationFrame` en Angular, `Ticker` / `SingleTickerProviderStateMixin` en Flutter), sin librerías externas de física.

**Ecuaciones de dominio puras (1D vertical):**
- Fuerza gravitatoria: $a_g = -g$
- Resistencia atmosférica cuadrática opuesta al movimiento:
  $$a_{\text{drag}} = -\text{sign}(v_y) \cdot k_d \cdot \rho \cdot v_y^2$$
  donde $\rho$ es la densidad atmosférica superficial real ($\text{kg/m}^3$) y $k_d = 0.0008\text{ m}^{-1}$ es el coeficiente aerodinámico efectivo de la sonda ($C_d A / (2m)$). En la Luna ($\rho = 0$), $a_{\text{drag}} = 0$.
- Empuje del propulsor principal (activo si `thrusterActive && fuel > 0`):
  $$a_{\text{thrust}} = a_{\text{max}} = 24.0\text{ m/s}^2$$
- Consumo de combustible:
  $$\Delta \text{fuel} = -r_{\text{fuel}} \cdot \Delta t_{\text{sim}}, \quad r_{\text{fuel}} = 3.5\text{ \%/s}$$
- Escala temporal por mundo ($\text{timeScale}$):
  $$\Delta t_{\text{sim}} = \Delta t_{\text{real}} \cdot \text{timeScale}$$
  Todas las magnitudes mostradas en telemetría y el umbral de impacto ($|v_y| \le 2.0\text{ m/s}$) se evalúan en unidades físicas reales (tiempo simulado), cumpliendo **FR-025** y **FR-026**.

**Tabla de Parámetros Calibrados por Mundo (garantiza SC-002 $\ge 15\%$ de reserva de combustible):**

| Mundo | $g$ ($\text{m/s}^2$) | $\rho$ ($\text{kg/m}^3$) | Altitud inicial $h_0$ ($\text{m}$) | Techo $1.5 \times h_0$ ($\text{m}$) | Velocidad inicial $v_0$ ($\text{m/s}$) | Combustible inicial | Escala temporal (`timeScale`) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Tierra** | `9.81` | `1.225` | `500` | `750` | `-25.0` | `100 %` | `×2` |
| **Marte** | `3.71` | `0.020` | `500` | `750` | `-20.0` | `100 %` | `×3` |
| **Luna** | `1.62` | `0.000` | `500` | `750` | `-15.0` | `100 %` | `×4` |
| **Titán** | `1.352` | `5.300` | `500` | `750` | `-12.0` | `100 %` | `×4` |

### Rationale
- Cumple el **Principio I** (constantes astrofísicas reales con margen $<1\%$, **SC-005**).
- Cumple el **Principio II** y **FR-010** (umbral único $|v_y| \le 2.0\text{ m/s}$ e invalidación por techo $1.5 \times h_0$, **FR-024**).
- Garantiza que un quemado suicida (*suicide burn*) óptimo deje entre $35\%$ y $65\%$ de combustible en los cuatro mundos, superando holgadamente el $15\%$ exigido por **SC-002**.

### Alternatives Considered
- **Motor de física externo (Matter.js, Cannon.js, Forge2D)**: Rechazado por prohibición expresa en la Constitución (*Restricciones del Producto*) y en las instrucciones del usuario.
- **Tiempo real sin escala (`timeScale = 1`)**: Rechazado porque en la Luna y Titán la caída desde $500\text{ m}$ tardaría más de 25 segundos reales, rompiendo la paridad de duración percibida (**FR-025**).

---

## 2. Renderizado 3D e Iluminación Crepuscular en Angular

### Decision
Implementar el lienzo de simulación 3D mediante **HTML5 `<canvas>` con proyección 3D en perspectiva matemática nativa / WebGL ligero encapsulado en un componente de presentación** (sin motores pesados ni dependencias de física), combinado con **CSS nativo / Tailwind local** para la cabina Weincode. Si se opta por Three.js empaquetado localmente, debe proponerse y aprobarse según la regla de *Cero Alucinaciones de Paquetes* de `angular-instructions.md`; por defecto, el motor de proyección 3D en Canvas/WebGL nativo en TypeScript cumple el 100% de **FR-027 a FR-030** con **cero dependencias npm adicionales**.

### Rationale
- El prompt del usuario pide para Angular: *"Angular, TypeScript, Tailwind/CSS nativo, sin dependencias externas pesadas"* y `.github/instructions/angular-instructions.md` ordena *"No añadas dependencias npm salvo petición explícita"*.
- Una escena 3D con cámara en tercera persona, malla de terreno con relieve perimetral (cráteres, rocas, vegetación, hielo), sonda tridimensional, sombras proyectadas según el ángulo solar (`solarElevation`, `cameraAzimuth`) y gradiente atmosférico Rayleigh/Mie se resuelve a 60 FPS en un `<canvas>` con pipeline de proyección 3D nativo en menos de 300 líneas de TypeScript puro.

### Alternatives Considered
- **Babylon.js / PlayCanvas**: Rechazados por ser dependencias pesadas que contradicen las restricciones del usuario.
- **Solo CSS 2D**: Rechazado porque la especificación (**FR-027 a FR-030**) y la Constitución v1.1.0 exigen escena 3D con cámara en tercera persona, rotación horizontal en Hora Solar y sombras dinámicas.

---

## 3. Renderizado 3D e Iluminación Crepuscular en Flutter

### Decision
Utilizar **`CustomPainter` con pipeline de transformación y proyección 3D en perspectiva (`Matrix4` de `vector_math` incluido en el SDK de Flutter)** sincronizado a 60 FPS mediante `SingleTickerProviderStateMixin` (`Ticker`), sin paquetes externos de `pub.dev`.

### Rationale
- `.github/instructions/flutter-instructions.md` prohíbe agregar paquetes externos de `pub.dev` sin solicitud explícita, y el README del proyecto define explícitamente para Flutter: `Flutter (Material 3, CustomPainter)`.
- Con `CustomPainter` + proyección 3D por vértices y caras ordenadas por profundidad (*Painter's algorithm* para el terreno, cráteres/rocas, sonda 3D y sombras proyectadas en el plano superficial), se logra una escena 3D fluida a 60 FPS en escritorio y móvil (**SC-010**) con 0 dependencias externas.

### Alternatives Considered
- **flutter_cube / flame_3d / impellers externos**: Rechazados por la regla *Cero Alucinaciones de Paquetes* de `flutter-instructions.md`.

---

## 4. Fidelidad Óptica Crepuscular ("Hora Solar") y Referencias Científicas

### Decision
Codificar en el dominio/catálogo local de cada mundo una curva continua de interpolación cromática en función de la elevación solar $\theta_{\text{sun}} \in [-10^\circ, 90^\circ]$:

1. **Tierra** (*Referencia: NASA Earth Observatory / Dispersión molecular de Rayleigh*):
   - $\theta > 30^\circ$: Cenit `#1E5799`, Horizonte `#7DB9E8`, Luz solar `#FFFDF4`.
   - $0^\circ \le \theta \le 30^\circ$: Cenit `#1B294A`, Horizonte `#FF5E1A` $\to$ `#D92B04`, Luz solar cálida `#FF8C42`.
   - $\theta < 0^\circ$: Crepúsculo civil/astronómico `#090D16` $\to$ `#020308`.
2. **Marte** (*Referencia: NASA Mars Science Laboratory Curiosity — PIA19400, Sol 956 Gale Crater sunset*):
   - $\theta > 25^\circ$: Cielo ocre/caramelo por polvo en suspensión (`#C67D50` cenit, `#E2A878` horizonte).
   - $0^\circ \le \theta \le 25^\circ$: Exterior pardo-rojizo (`#6E473B`) con **halo azul frío/grisáceo alrededor del disco solar** (`#6C93B8` $\to$ `#8FB8DE`) por dispersión Mie hacia adelante en polvo fino marciano.
   - $\theta < 0^\circ$: Oscurecimiento ocre oscuro a negro marciano (`#1A110E`).
3. **Luna** (*Referencia: NASA Apollo 11–17 Surface Photography & LRO — Ausencia de atmósfera, $\rho = 0$*):
   - Cielo negro absoluto permanente (`#000000`) a cualquier elevación solar ($\theta \in [-10^\circ, 90^\circ]$).
   - Iluminación de terreno y sonda con sombras negras duras (contraste 100%, luz ambiental de cielo = `0`).
   - Al cruzar $\theta < 0^\circ$, corte abrupto de iluminación directa en el horizonte.
4. **Titán** (*Referencia: ESA/NASA/JPL-Caltech Huygens DISR Surface Images, 14 enero 2005*):
   - $\theta > 20^\circ$: Bruma densa ámbar/anaranjada uniforme (`#B85D19` cenit, `#D9822B` horizonte) por aerosoles de tolinas orgánicas.
   - $0^\circ \le \theta \le 20^\circ$: Transición difusa a ámbar quemado (`#6E320C` $\to$ `#3D1A05`), disco solar apenas discernido como resplandor difuso, sombras muy suaves.
   - $\theta < 0^\circ$: Bruma marrón-negra profunda (`#120702`).

### Rationale
- Cumple estrictamente **FR-015**, **FR-016**, **SC-006** y el **Principio I**.
- Ninguno de los colores de cielo o terreno utiliza la paleta Weincode (`#18084D`, `#5236FF`, `#A599FF`, `#FFFFFF`), preservando el **Principio III** y **FR-021**.
