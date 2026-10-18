# Feature Specification: Descenso Planetario y Hora Solar (WeinSolar v1)

**Feature Branch**: `001-planetary-lander-sunset`  
**Created**: 2026-10-17  
**Status**: Cerrada — lista para planificación (2026-10-17)  
**Input**: User description: "4 mundos iniciales (Tierra, Marte, Luna, Titán). El usuario selecciona un mundo, inicia a cierta altitud cayendo hacia la superficie y tiene propulsores con combustible limitado para frenar. Si aterriza suave (por debajo de la velocidad límite) gana y aparece el control 'Hora Solar' para mover el sol hacia el horizonte y ver el color del cielo propio de ese mundo (atardecer naranja en la Tierra, azul frío en Marte, corte negro sin atmósfera en la Luna, bruma densa ámbar en Titán). Si choca fuerte o se queda sin combustible y cae rápido, la sonda se destruye y no puede ver el anochecer hasta que reintente y aterrice. Sin decidir: umbrales de velocidad segura, salida por arriba de la pantalla, viento lateral, reinicio y presentación de métricas en la cabina morada de Weincode."

## Clarifications

### Session 2026-10-17

- Q: ¿v1 incluye eje horizontal o viento? → A: No; descenso solo vertical, sin viento (velocidad horizontal siempre 0).
- Q: ¿Umbral de aterrizaje seguro? → A: Velocidad vertical ≤ 2,0 m/s, único para los cuatro mundos (tolerancia de la sonda).
- Q: ¿Qué ocurre si la sonda sale por arriba? → A: Techo de altitud de 1,5 × la altitud inicial; superarlo es "Misión fallida – señal perdida".
- Q: ¿La simulación corre en tiempo real o acelerado? → A: Tiempo acelerado por mundo para que todos los descensos duren parecido (solo se acelera la reproducción; las ecuaciones y constantes no cambian).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Aterrizar la sonda en un mundo (Priority: P1)

El usuario abre el simulador, elige uno de los cuatro mundos y la sonda aparece a una altitud inicial cayendo hacia la superficie bajo la gravedad y la atmósfera reales de ese mundo. Mientras mantiene activado el propulsor, la sonda frena a costa de consumir combustible. Al tocar la superficie, el sistema compara la velocidad de contacto con el umbral de tolerancia de la sonda y declara la misión como **éxito** o **fallida**.

**Why this priority**: Es el núcleo del producto: sin el descenso controlado no hay juego, ni mérito, ni recompensa. Por sí solo ya es un simulador jugable y educativo.

**Independent Test**: Seleccionar cualquier mundo, descender y tocar suelo una vez frenando bien y otra sin frenar; se verifica que el primer intento se declara éxito y el segundo fallido, y que la caída se comporta distinto en cada mundo.

**Acceptance Scenarios**:

1. **Given** la pantalla de selección, **When** el usuario elige "Marte", **Then** la sonda aparece en la altitud inicial de Marte con el tanque lleno y comienza a caer con la gravedad marciana (3,71 m/s²).
2. **Given** una sonda en descenso con combustible, **When** el usuario mantiene el propulsor activo, **Then** la velocidad de caída disminuye y el indicador de combustible baja de forma continua.
3. **Given** una sonda a punto de tocar suelo, **When** contacta la superficie con velocidad vertical igual o inferior al umbral seguro, **Then** se declara "Aterrizaje exitoso".
4. **Given** una sonda a punto de tocar suelo, **When** contacta la superficie con velocidad superior al umbral seguro, **Then** se declara inmediatamente "Misión fallida", la sonda se muestra destruida y el control Hora Solar no aparece.
5. **Given** una sonda sin combustible, **When** el usuario intenta activar el propulsor, **Then** el propulsor no produce empuje y la sonda sigue cayendo libremente hasta la superficie, donde se evalúa el impacto con la misma regla.
6. **Given** una sonda en descenso, **When** el usuario impulsa hasta superar 1,5 × la altitud inicial, **Then** se declara "Misión fallida – señal perdida" y Hora Solar no aparece.
7. **Given** contactos a 2,0 m/s y a 2,1 m/s en cualquier mundo, **When** se evalúa el aterrizaje, **Then** el primero es éxito y el segundo es misión fallida.
8. **Given** el mismo perfil de pilotaje (sin usar propulsor), **When** se deja caer la sonda en la Luna y en la Tierra, **Then** la velocidad de impacto es claramente distinta, reflejando la gravedad y la atmósfera de cada mundo.

---

### User Story 2 - Contemplar el anochecer con "Hora Solar" (Priority: P2)

Tras un aterrizaje exitoso, aparece el control "Hora Solar". El usuario lo desplaza para llevar el sol desde lo alto del cielo hasta el horizonte y por debajo de él, y observa cómo el color del cielo cambia según la óptica real de ese mundo.

**Why this priority**: Es la recompensa que da sentido al descenso y el diferenciador educativo del producto, pero depende de que exista un aterrizaje exitoso (P1).

**Independent Test**: Lograr un aterrizaje exitoso en cada mundo, mover Hora Solar de extremo a extremo y comparar el cielo resultante con la referencia cromática documentada de cada mundo.

**Acceptance Scenarios**:

1. **Given** un aterrizaje exitoso, **When** se muestra el resultado, **Then** aparece el control Hora Solar con el sol en posición alta.
2. **Given** un aterrizaje exitoso en la Tierra, **When** el usuario lleva el sol al horizonte, **Then** el cielo transita de azul a tonos naranjas y rojizos cerca del horizonte.
3. **Given** un aterrizaje exitoso en Marte, **When** el usuario lleva el sol al horizonte, **Then** el cielo diurno ocre/caramelo muestra un halo azul frío alrededor del sol.
4. **Given** un aterrizaje exitoso en la Luna, **When** el usuario mueve el sol a cualquier altura, **Then** el cielo permanece negro, sin gradiente atmosférico, y al cruzar el horizonte la luz desaparece de forma abrupta.
5. **Given** un aterrizaje exitoso en Titán, **When** el usuario lleva el sol al horizonte, **Then** el cielo muestra una bruma densa ámbar/anaranjada que se oscurece de forma difusa y gradual.
6. **Given** una misión fallida, **When** se muestra el resultado, **Then** el control Hora Solar no está disponible de ninguna forma.

---

### User Story 3 - Reintentar o cambiar de mundo (Priority: P3)

Al terminar un intento (éxito o fallo), el usuario puede reintentar el mismo mundo desde las condiciones iniciales o volver a la selección para elegir otro.

**Why this priority**: Cierra el bucle de aprendizaje (fallar → reintentar → desbloquear el anochecer) que exige la constitución, pero el producto ya es demostrable sin él recargando la página.

**Independent Test**: Provocar un fallo, pulsar "Reintentar" y comprobar que la sonda reaparece con altitud, velocidad y combustible iniciales; luego pulsar "Cambiar mundo" y comprobar que se vuelve a la selección.

**Acceptance Scenarios**:

1. **Given** una misión fallida, **When** el usuario pulsa "Reintentar", **Then** el mismo mundo se reinicia con altitud, velocidad y combustible iniciales, y Hora Solar sigue bloqueada.
2. **Given** cualquier resultado final, **When** el usuario pulsa "Cambiar mundo", **Then** vuelve a la pantalla de selección de los cuatro mundos.
3. **Given** un descenso en curso, **When** el usuario pulsa "Reiniciar", **Then** el intento actual se descarta y el mundo se reinicia desde las condiciones iniciales.

---

### User Story 4 - Leer la telemetría en la cabina Weincode (Priority: P3)

Durante todo el descenso el usuario ve una cabina (HUD) con los colores de Weincode que muestra en tiempo real las métricas necesarias para decidir cuándo frenar.

**Why this priority**: Sin telemetría el aterrizaje es adivinanza; es imprescindible para una buena experiencia, aunque una versión mínima de P1 puede probarse con métricas básicas.

**Independent Test**: Iniciar un descenso y verificar que cada métrica listada se actualiza de forma continua y coherente, y que el HUD usa exclusivamente la paleta oficial sin teñir el cielo.

**Acceptance Scenarios**:

1. **Given** un descenso en curso, **When** el usuario observa la cabina, **Then** ve altitud, velocidad vertical, combustible restante, nombre del mundo, su gravedad y el umbral de aterrizaje seguro.
2. **Given** una velocidad vertical superior al umbral seguro, **When** se muestra la telemetría, **Then** la velocidad aparece destacada como "peligrosa"; al bajar del umbral aparece como "segura".
3. **Given** cualquier pantalla, **When** se inspecciona la cabina, **Then** solo se usan los colores #18084D, #5236FF, #A599FF y #FFFFFF, y ninguno de ellos tiñe el cielo ni el terreno.

---

### Edge Cases

- **Combustible agotado en el aire**: el propulsor deja de responder, la cabina indica "Sin combustible" y la sonda cae libremente; el resultado se decide solo por la velocidad de contacto (puede aún ser éxito si ya iba lenta).
- **Impulso excesivo hacia arriba**: existe un techo de altitud igual a 1,5 × la altitud inicial del mundo; si la sonda lo supera, se pierde la señal y el intento se declara "Misión fallida – señal perdida", con Hora Solar bloqueada (FR-024).
- **Velocidad exactamente igual al umbral**: cuenta como aterrizaje exitoso (el umbral es inclusivo).
- **Propulsor activo en el instante de contacto**: no altera la regla; solo importa la velocidad de contacto.
- **Cambio de pestaña o pérdida de foco**: la simulación se pausa y se reanuda al volver, sin que el tiempo pausado afecte la física.
- **Selección de mundo durante un descenso**: no está disponible sin antes reiniciar o abandonar el intento.
- **Hora Solar tras éxito y luego Reintentar**: el control vuelve a bloquearse hasta el siguiente aterrizaje exitoso.

## Requirements *(mandatory)*

### Functional Requirements

**Selección de mundo**

- **FR-001**: El sistema MUST ofrecer exactamente cuatro mundos seleccionables en v1: Tierra, Marte, Luna y Titán.
- **FR-002**: La pantalla de selección MUST mostrar para cada mundo su nombre y su gravedad superficial.

**Física del descenso**

- **FR-003**: Al iniciar un intento, la sonda MUST aparecer a la altitud inicial, con la velocidad inicial y el combustible inicial definidos para el mundo elegido.
- **FR-004**: El descenso MUST aplicar la gravedad superficial real del mundo (ver tabla de Constantes Planetarias).
- **FR-005**: El descenso MUST aplicar la resistencia atmosférica correspondiente a la densidad atmosférica real del mundo; en la Luna la resistencia MUST ser nula.
- **FR-006**: El usuario MUST poder activar y desactivar el propulsor principal en cualquier momento del descenso; mientras está activo MUST generar empuje opuesto a la caída y consumir combustible de forma proporcional al tiempo de uso.
- **FR-007**: Con el combustible en cero, el propulsor MUST dejar de generar empuje.
- **FR-025**: Cada mundo MUST tener un factor de escala temporal fijo que acelera la reproducción del descenso para que la duración percibida sea similar entre mundos. El factor MUST NOT alterar gravedad, densidad, empuje ni umbrales: la trayectoria simulada MUST ser idéntica a la de tiempo real, solo reproducida más rápido.
- **FR-026**: Todas las magnitudes de la cabina (velocidad, altitud, consumo) y la evaluación del umbral de 2,0 m/s MUST expresarse en tiempo simulado (unidades físicas reales), nunca en tiempo de pantalla; la cabina MUST indicar el factor de escala activo (p. ej. "×4").
- **FR-008**: En v1 el descenso MUST ser exclusivamente vertical: no hay propulsores laterales ni viento, y la velocidad horizontal de la sonda es siempre 0.

**Resultado del aterrizaje**

- **FR-009**: Al contactar la superficie, el sistema MUST declarar éxito si la velocidad de contacto es menor o igual al umbral seguro, y misión fallida si lo supera.
- **FR-010**: El umbral seguro de contacto MUST ser una velocidad vertical ≤ 2,0 m/s, idéntico en los cuatro mundos por ser una propiedad estructural de la sonda (no del mundo).
- **FR-011**: Ante una misión fallida, el sistema MUST mostrar la sonda destruida, el motivo del fallo y la velocidad de impacto registrada.
- **FR-012**: Ante una misión fallida, el sistema MUST bloquear por completo el acceso a Hora Solar y al anochecer hasta que se logre un aterrizaje exitoso en un intento posterior.
- **FR-013**: Ante un éxito, el sistema MUST mostrar la velocidad de contacto y el combustible restante.
- **FR-024**: El sistema MUST definir por mundo un techo de altitud igual a 1,5 × su altitud inicial; si la sonda lo supera, el intento MUST declararse inmediatamente "Misión fallida – señal perdida" y aplicar el mismo bloqueo de FR-012.

**Hora Solar**

- **FR-014**: Tras un aterrizaje exitoso, el sistema MUST mostrar el control "Hora Solar", que permite al usuario mover de forma continua la posición del sol desde lo alto del cielo hasta por debajo del horizonte, en ambos sentidos.
- **FR-015**: El color del cielo MUST cambiar de forma continua según la posición del sol y conforme a la óptica real del mundo: Tierra (azul → naranja/rojo en el horizonte), Marte (cielo ocre con halo azul frío alrededor del sol en el ocaso), Luna (cielo siempre negro, sin gradiente; corte abrupto de luz al cruzar el horizonte), Titán (bruma densa ámbar/anaranjada que se oscurece gradualmente).
- **FR-016**: Cada transición cromática MUST estar respaldada por una referencia científica documentada (observaciones o imágenes de misiones) registrada junto a las constantes del mundo.

**Reinicio**

- **FR-017**: Tras cualquier resultado, el usuario MUST poder elegir "Reintentar" (mismo mundo, condiciones iniciales) o "Cambiar mundo" (volver a la selección).
- **FR-018**: Durante el descenso, el usuario MUST poder reiniciar el intento actual.

**Cabina y telemetría**

- **FR-019**: Durante el descenso, la cabina MUST mostrar en tiempo real: altitud sobre la superficie, velocidad vertical, combustible restante (en porcentaje), mundo actual, su gravedad, el umbral seguro (2,0 m/s) y el techo de altitud, con aviso cuando la sonda se acerque a él.
- **FR-020**: La cabina MUST indicar visualmente si la velocidad vertical actual está por encima o por debajo del umbral seguro.
- **FR-021**: Toda la interfaz de cabina, controles, selectores y telemetría MUST usar exclusivamente la paleta Weincode (#18084D, #5236FF, #A599FF, #FFFFFF), y esa paleta MUST NOT teñir el cielo ni el terreno simulado.
- **FR-022**: El usuario MUST poder controlar el propulsor tanto con teclado como con un control táctil/clic en pantalla.

**Autonomía**

- **FR-023**: El ciclo completo (selección, descenso, resultado, Hora Solar, reinicio) MUST funcionar sin cuentas de usuario, sin conexión a red y sin servicios remotos una vez abierto el simulador.

### Key Entities

- **Mundo**: cuerpo celeste jugable. Atributos: nombre, gravedad superficial, densidad atmosférica superficial, factor de escala temporal, altitud inicial del descenso, techo de altitud (1,5 × altitud inicial), combustible inicial, paleta de cielo por posición solar y referencia científica de la paleta.
- **Sonda**: vehículo del usuario. Atributos: altitud, velocidad vertical, combustible restante, estado (en descenso, aterrizada, destruida, señal perdida), umbral de tolerancia de impacto (2,0 m/s).
- **Intento (Misión)**: un descenso desde condiciones iniciales hasta el contacto, la pérdida de señal o el reinicio. Atributos: mundo, resultado (éxito/fallido por impacto/fallido por señal perdida/abandonado), velocidad de contacto, combustible restante.
- **Hora Solar**: posición del sol respecto al horizonte del mundo, controlada por el usuario solo tras un intento exitoso; determina el color del cielo.

### Constantes Planetarias (referencia de fidelidad)

| Mundo  | Gravedad superficial | Densidad atmosférica en superficie | Carácter del ocaso |
|--------|----------------------|------------------------------------|--------------------|
| Tierra | 9,81 m/s²            | ≈ 1,225 kg/m³                      | Azul diurno → naranja/rojo en el horizonte (dispersión de Rayleigh) |
| Marte  | 3,71 m/s²            | ≈ 0,020 kg/m³                      | Cielo ocre; halo azul frío alrededor del sol (dispersión por polvo fino) |
| Luna   | 1,62 m/s²            | 0 (sin atmósfera)                  | Cielo negro permanente; corte de luz abrupto |
| Titán  | 1,352 m/s²           | ≈ 5,3 kg/m³                        | Bruma densa ámbar/anaranjada (neblina orgánica), oscurecimiento difuso |

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un usuario nuevo puede pasar de abrir el simulador a iniciar su primer descenso en menos de 30 segundos.
- **SC-002**: En cada uno de los cuatro mundos, un aterrizaje exitoso es alcanzable con el combustible inicial dejando al menos un 15 % de reserva cuando se pilota de forma óptima (verificado en pruebas de juego).
- **SC-003**: Al menos el 70 % de los usuarios de prueba logra su primer aterrizaje exitoso en 5 intentos o menos en al menos un mundo.
- **SC-004**: El 100 % de los intentos con velocidad de contacto por encima del umbral se declaran fallidos y el 100 % de ellos impide el acceso a Hora Solar.
- **SC-005**: Las gravedades y densidades usadas coinciden con la tabla de Constantes Planetarias con un margen máximo del 1 %.
- **SC-006**: En una revisión visual, observadores comparan el ocaso de cada mundo con su referencia científica y lo identifican correctamente en al menos el 90 % de los casos (los cuatro cielos son distinguibles entre sí).
- **SC-007**: La telemetría refleja el estado de la sonda sin retraso perceptible: el usuario ve el efecto de activar el propulsor en la velocidad mostrada en menos de 0,1 s.
- **SC-008**: Reintentar devuelve al usuario a un nuevo descenso en menos de 2 segundos.
- **SC-009**: El ciclo completo funciona con la red desconectada tras la apertura inicial.

## Assumptions

- **Plataforma**: experiencia 2D de una sola pantalla en navegador de escritorio y móvil; el propulsor se controla con una tecla (p. ej. barra espaciadora/flecha arriba) o manteniendo pulsado un botón en pantalla.
- **Condiciones iniciales**: la altitud inicial, la velocidad inicial y el combustible inicial son parámetros de partida del escenario (no constantes físicas) y se calibran por mundo para que el aterrizaje sea exigente pero alcanzable (SC-002); la física durante el descenso no se altera para facilitar el juego. El factor de escala temporal (FR-025) es solo de reproducción y se considera compatible con el Principio I porque no modifica ninguna constante ni la trayectoria.
- **Empuje del propulsor**: el empuje y el consumo son propiedades de la sonda y son iguales en todos los mundos; la diferencia de dificultad proviene solo de la gravedad y la atmósfera reales.
- **Reinicio**: reintentar no tiene límite ni penalización; no se guarda historial ni puntuaciones entre sesiones en v1.
- **Progreso**: el desbloqueo de Hora Solar aplica solo al intento exitoso en curso; no se persiste entre sesiones.
- **Terreno**: la superficie de aterrizaje es plana en v1; no hay obstáculos ni zonas de aterrizaje específicas.
- **Idioma**: interfaz en español en v1.
- **Fuera de alcance v1**: más mundos, movimiento lateral y viento, puntuaciones/rankings, sonido, modos multijugador, rotación/actitud de la sonda.
