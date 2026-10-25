# Feature Specification: Entorno Tridimensional Realista (WeinSolar v2)

**Feature Branch**: `002-realistic-3d-scene`  
**Created**: 2026-10-19  
**Status**: Draft  
**Input**: User description: "El objetivo de negocio es elevar la calidad visual de un entorno 2D vectorial plano a un entorno tridimensional (3D) realista, manteniendo intactas todas las leyes físicas y reglas de negocio de la v1. Lo que sabemos: la interfaz de cabina (UI de Weincode) se mantiene estática en 2D sobrepuesta a la simulación; la sonda y el terreno del planeta deben representarse con volumen y perspectiva real; la transición de 'Hora Solar' debe proyectar sombras dinámicas sobre el terreno que se alargan conforme el sol se acerca al horizonte, y los materiales de la nave deben reflejar los tintes del atardecer (ej. reflejo azulado en Marte). Por descubrir: comportamiento de la cámara (fija lateral siguiendo a la sonda o rotación libre 360° alrededor de la nave) y física del terreno (¿la nave puede volcarse en el borde de un cráter o se garantiza una plataforma siempre plana?)."

## Contexto y alcance del cambio

La v1 (`specs/001-planetary-lander-sunset/spec.md`) define el comportamiento completo del simulador: selección de mundo, descenso vertical con gravedad y atmósfera reales, umbral de impacto de 2,0 m/s, techo de señal, Hora Solar como recompensa, reinicio y cabina Weincode. Su representación visual actual es plana: la sonda, el terreno y el cielo se dibujan como formas sin volumen real.

Esta v2 es un **cambio exclusivamente de presentación**: eleva la escena a volumen, perspectiva, iluminación y sombras realistas. Toda ley física, constante planetaria, umbral, regla de mérito y flujo de pantallas de la v1 se hereda **sin modificación**. Cualquier requisito de esta spec que entre en conflicto con la v1 o con la constitución se resuelve a favor de estas últimas.

## Clarifications

### Session 2026-10-19

- Q: ¿Comportamiento de la cámara? → A: Mixta: durante el descenso, cámara que sigue a la sonda desde un ángulo lateral fijo, sin control del usuario; tras un aterrizaje exitoso, en Hora Solar el usuario puede girar la vista 360° alrededor de la nave.
- Q: ¿La nave puede volcar en el borde de un cráter o la plataforma es siempre plana? → A: Plataforma siempre plana; el relieve y los cráteres son decorativos y quedan fuera de la trayectoria de la sonda. No hay vuelco ni nueva causa de fallo.
- Q: ¿Qué ocurre en dispositivos sin capacidad para la calidad visual completa? → A: El usuario elige manualmente en la cabina entre calidad «Alta» y «Básica»; no hay ajuste automático.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Descender sobre un mundo con volumen y perspectiva real (Priority: P1)

El usuario elige un mundo y ve la sonda como un objeto sólido con volumen, iluminado por el sol de ese mundo, descendiendo sobre un terreno con relieve real (rocas, cráteres, dunas o hielo según el mundo) que se percibe en profundidad. A medida que baja, el terreno crece en pantalla y la sombra de la sonda sobre el suelo se acerca a ella, reforzando visualmente la lectura de altitud. La cabina Weincode permanece fija en primer plano, plana y legible, sin girar ni deformarse con la escena.

**Why this priority**: Es el objetivo de negocio central (salto de calidad visual) y aplica a 100 % de las sesiones, incluidas las que terminan en fallo. Sin esta historia no hay v2.

**Independent Test**: Iniciar un descenso en cada uno de los cuatro mundos y comprobar que la sonda y el terreno se perciben con volumen y profundidad, que la sombra de la sonda converge con ella al acercarse al suelo, que la cabina permanece estática y que el resultado del aterrizaje es idéntico al de la v1 para el mismo perfil de pilotaje.

**Acceptance Scenarios**:

1. **Given** la pantalla de selección, **When** el usuario elige cualquier mundo, **Then** la sonda aparece como un objeto con volumen iluminado desde la dirección del sol, sobre un terreno con relieve característico de ese mundo y visto en perspectiva.
2. **Given** un descenso en curso, **When** la sonda pierde altitud, **Then** la sombra de la sonda proyectada sobre el terreno se aproxima a ella de forma continua y coincide con su base en el instante del contacto.
3. **Given** un descenso en curso, **When** el usuario observa la pantalla, **Then** la cabina permanece en la misma posición, tamaño y orientación durante todo el intento, superpuesta a la escena, independientemente de lo que haga la cámara.
4. **Given** el mismo perfil de pilotaje ejecutado en la v1 y en la v2 sobre el mismo mundo, **When** la sonda toca la superficie, **Then** la velocidad de contacto, el combustible restante y el resultado (éxito o fallo) son idénticos.
5. **Given** una misión fallida por impacto, **When** se muestra el resultado, **Then** la sonda se ve destruida en la escena con volumen y Hora Solar permanece bloqueada.

---

### User Story 2 - Ver el atardecer proyectar sombras y teñir la nave (Priority: P2)

Tras un aterrizaje exitoso, el usuario mueve el control Hora Solar. Conforme el sol baja hacia el horizonte, las sombras de la sonda y del relieve se alargan sobre el terreno y cambian de dirección siguiendo al sol; las superficies de la nave reflejan el tinte propio del ocaso de ese mundo (azulado en Marte, anaranjado-rojizo en la Tierra, ámbar difuso en Titán, luz blanca dura sin tinte en la Luna). Al cruzar el horizonte, las sombras desaparecen y la escena se oscurece según la óptica del mundo.

**Why this priority**: Es la recompensa crepuscular que exige la constitución, ahora potenciada; depende de que exista un aterrizaje exitoso (P1).

**Independent Test**: Lograr un aterrizaje exitoso en cada mundo, recorrer Hora Solar de extremo a extremo y verificar la longitud y dirección de las sombras y el tinte reflejado en la nave contra la referencia de cada mundo.

**Acceptance Scenarios**:

1. **Given** un aterrizaje exitoso con el sol en lo alto, **When** el usuario baja el sol hacia el horizonte, **Then** la longitud de las sombras sobre el terreno aumenta de forma continua y monótona.
2. **Given** el sol a una altura de 45° sobre el horizonte, **When** se mide la sombra de un elemento vertical del terreno o de la sonda, **Then** su longitud es aproximadamente igual a la altura del elemento (±10 %); a 10° de altura solar es al menos 5 veces su altura.
3. **Given** un aterrizaje exitoso en Marte, **When** el sol está cerca del horizonte, **Then** las caras de la nave orientadas al sol muestran un reflejo azulado coherente con el halo azul del ocaso marciano, y el resto de la escena conserva los tonos ocres.
4. **Given** un aterrizaje exitoso en la Luna, **When** el usuario mueve el sol, **Then** las sombras son de borde nítido y completamente oscuras, la nave no adquiere ningún tinte de cielo y, al cruzar el horizonte, la luz desaparece de forma abrupta.
5. **Given** un aterrizaje exitoso en Titán, **When** el usuario mueve el sol, **Then** las sombras son suaves y difusas por la bruma y la nave adquiere un tinte ámbar que se oscurece gradualmente.
6. **Given** el sol por debajo del horizonte, **When** se observa la escena, **Then** no se proyectan sombras solares y la iluminación residual corresponde a la del cielo nocturno o crepuscular del mundo.
7. **Given** cualquier posición del sol, **When** se inspeccionan el cielo, el terreno, la nave y sus reflejos, **Then** ninguno contiene ni refleja los colores de la paleta Weincode.

---

### User Story 3 - Observar la escena desde el ángulo de cámara definido (Priority: P3)

Durante el descenso, la cámara sigue a la sonda desde un ángulo lateral fijo para que el usuario juzgue siempre la distancia al suelo sin distraerse. Tras un aterrizaje exitoso, el usuario puede girar la vista 360° alrededor de la nave para contemplar el ocaso y las sombras desde cualquier lado.

**Why this priority**: Mejora la lectura espacial y la contemplación, pero la v2 ya aporta su valor central (P1, P2) con una cámara fija.

**Independent Test**: Realizar un descenso completo comprobando que la cámara no responde a controles y mantiene el ángulo lateral; luego, en Hora Solar, girar la vista una vuelta completa comprobando que la nave permanece centrada.

**Acceptance Scenarios**:

1. **Given** un descenso en curso, **When** la sonda se acerca al suelo, **Then** la sonda y la zona de contacto permanecen visibles en todo momento, sin que el terreno ni otros elementos las oculten.
2. **Given** un aterrizaje exitoso, **When** comienza Hora Solar, **Then** la cámara muestra la sonda, el horizonte por donde se pone el sol y las sombras proyectadas sobre el terreno.
3. **Given** un descenso en curso, **When** el usuario intenta arrastrar o girar la vista, **Then** la cámara mantiene el ángulo lateral fijo.
4. **Given** Hora Solar activa, **When** el usuario gira la vista 360°, **Then** la nave permanece centrada, la cabina no se mueve y el sol, las sombras y los reflejos se ven coherentes desde cada ángulo.
5. **Given** una misión fallida, **When** se muestra el resultado, **Then** la vista no se puede girar.

---

### Edge Cases

- **Sol rasante (altura cercana a 0°)**: las sombras pueden alargarse hasta salir del área visible; la escena MUST seguir mostrando su dirección sin artefactos visuales (parpadeos, cortes o sombras que atraviesen la nave).
- **Sol justo en el horizonte**: la transición de "con sombras" a "sin sombras solares" es continua en la Tierra, Marte y Titán, y abrupta en la Luna, coherente con la transición de cielo de la v1.
- **Sombra de la sonda sobre relieve irregular**: con el sol bajo, la sombra puede salir de la plataforma plana; entonces se adapta a la forma del terreno (se deforma sobre rocas y pendientes), no se dibuja como una mancha plana flotante.
- **Sonda destruida**: los restos se muestran con volumen e iluminación de la escena; no se habilita Hora Solar ni la cámara de contemplación.
- **Pérdida de señal por techo de altitud**: la sonda puede salir del encuadre por arriba; la cabina sigue mostrando el estado "Misión fallida – señal perdida" igual que en la v1.
- **Dispositivo con capacidad gráfica limitada**: la escena arranca en «Alta» y puede ir lenta; el usuario puede cambiar a «Básica» desde la cabina en cualquier momento, incluso a mitad del descenso, sin que cambie el intento (FR-019).
- **Pantalla estrecha o rotación del dispositivo**: la cabina se recoloca sin superponerse a la sonda ni a la zona de contacto; la escena se reencuadra sin alterar la física.
- **Cambio de pestaña o pérdida de foco**: igual que en la v1 (pausa sin afectar la física); al volver, sombras e iluminación corresponden exactamente al estado pausado.

## Requirements *(mandatory)*

### Functional Requirements

**Invariantes heredadas de la v1 (no negociables)**

- **FR-001**: Todas las constantes planetarias, la física de descenso (exclusivamente vertical, velocidad horizontal 0), el empuje y consumo del propulsor, el factor de escala temporal, el umbral seguro de 2,0 m/s, el techo de altitud de 1,5 × la altitud inicial y las reglas de éxito/fallo MUST ser idénticas a las de la v1 (FR-001 a FR-026 de `001-planetary-lander-sunset`).
- **FR-002**: Ningún elemento visual nuevo (relieve, sombras, cámara, materiales) MUST alterar la trayectoria, la detección del contacto ni el resultado de un intento: para el mismo perfil de pilotaje, la v1 y la v2 MUST producir la misma velocidad de contacto, combustible restante y resultado.
- **FR-003**: Hora Solar MUST seguir disponible solo tras un aterrizaje exitoso y MUST seguir bloqueada por completo tras cualquier misión fallida (impacto o señal perdida).
- **FR-004**: El flujo de pantallas (selección, descenso, resultado, Hora Solar, reintentar, cambiar mundo, reiniciar) MUST mantenerse igual que en la v1.

**Cabina superpuesta**

- **FR-005**: La cabina, la telemetría y los controles MUST mostrarse como una capa plana, estática y superpuesta a la escena: su posición, tamaño, orientación y legibilidad MUST NOT variar por movimientos de cámara, iluminación o sombras de la escena.
- **FR-006**: La cabina MUST usar exclusivamente la paleta Weincode (#18084D, #5236FF, #A599FF, #FFFFFF), y ningún elemento de la escena (cielo, terreno, sonda, sombras, reflejos o iluminación) MUST contener ni reflejar esos colores.

**Volumen y perspectiva**

- **FR-007**: La sonda MUST representarse como un objeto sólido con volumen apreciable desde cualquier ángulo de cámara permitido, con caras iluminadas y en sombra según la dirección del sol.
- **FR-008**: El terreno de cada mundo MUST representarse con relieve tridimensional característico (Tierra: rocas y vegetación; Marte: regolito rojizo y rocas; Luna: regolito gris con cráteres; Titán: terreno helado bajo bruma), visto en perspectiva con sensación de profundidad hasta el horizonte.
- **FR-009**: Durante el descenso, la sonda MUST proyectar una sombra sobre el terreno coherente con la posición inicial del sol, cuya distancia a la sonda disminuya conforme baja la altitud y que coincida con su base en el contacto.

**Cámara**

- **FR-010**: Durante el descenso, la cámara MUST seguir a la sonda desde un ángulo lateral fijo, sin control del usuario. Tras un aterrizaje exitoso, en Hora Solar el usuario MUST poder girar la vista 360° alrededor de la nave (con teclado, arrastre de ratón o gesto táctil), manteniendo la nave en el centro del encuadre. Tras una misión fallida, la cámara MUST permanecer en el ángulo lateral fijo.
- **FR-011**: En cualquier modo de cámara, la sonda y la zona de contacto MUST permanecer visibles durante todo el descenso.

**Terreno y zona de contacto**

- **FR-012**: Cada mundo MUST tener una plataforma de aterrizaje plana y horizontal bajo la trayectoria vertical de la sonda. El relieve (rocas, cráteres, pendientes, dunas) MUST ser decorativo y quedar fuera de esa plataforma, sin interferir con la trayectoria ni con el contacto. La sonda MUST NOT volcar, inclinarse ni deslizarse al aterrizar; el resultado depende solo de la velocidad de contacto (FR-001).
- **FR-021**: La plataforma MUST integrarse visualmente en el terreno de cada mundo (mismos materiales y continuidad con el relieve circundante), sin parecer un objeto artificial añadido.

**Iluminación, sombras y materiales en Hora Solar**

- **FR-013**: La posición del sol en Hora Solar MUST determinar la dirección y longitud de todas las sombras de la escena: la longitud de una sombra MUST ser coherente con la altura solar (≈ altura del objeto / tangente de la altura solar) y aumentar de forma continua al acercarse el sol al horizonte.
- **FR-014**: Con el sol por debajo del horizonte, la escena MUST NOT proyectar sombras solares.
- **FR-015**: La nitidez de las sombras MUST corresponder a la atmósfera de cada mundo: bordes nítidos y oscuridad total en la Luna; bordes suaves y difusos en Titán; intermedios en la Tierra y Marte.
- **FR-016**: Las superficies de la sonda MUST reflejar el color de la luz y del cielo del mundo en cada posición solar: tinte azulado cerca del sol en el ocaso marciano, anaranjado-rojizo en el ocaso terrestre, ámbar difuso en Titán y luz blanca sin tinte de cielo en la Luna.
- **FR-017**: Los tintes de iluminación y reflejo MUST derivarse de la misma referencia científica documentada que la paleta de cielo de cada mundo (FR-015 y FR-016 de la v1); queda prohibido introducir tintes decorativos sin respaldo.
- **FR-018**: Las transiciones de iluminación, sombras y reflejos MUST ser continuas al mover Hora Solar en ambos sentidos, sin saltos visibles (salvo el corte abrupto de la Luna al cruzar el horizonte).

**Rendimiento y autonomía**

- **FR-019**: La cabina MUST ofrecer un selector de calidad visual con dos niveles, «Alta» y «Básica», con «Alta» seleccionado por defecto. El usuario MUST poder cambiarlo en la pantalla de selección y en cualquier fase del intento; el cambio MUST aplicarse en menos de 2 segundos y MUST NOT alterar la física, el estado del intento ni el resultado. El sistema MUST NOT cambiar el nivel automáticamente. La elección no se conserva entre sesiones.
- **FR-022**: «Básica» MAY simplificar el detalle del relieve, la suavidad de los bordes de sombra y la riqueza de los reflejos, pero MUST conservar el volumen de la sonda y del terreno, la dirección y longitud de las sombras (FR-013, FR-014), los tintes de cada mundo (FR-016, FR-017), el corte abrupto lunar y la cabina superpuesta.
- **FR-020**: Todos los recursos visuales de la escena (forma de la sonda, relieve y superficies del terreno, iluminación) MUST estar incluidos en la aplicación; el ciclo completo MUST seguir funcionando sin conexión a red tras la apertura.

### Key Entities

- **Escena del mundo**: representación con volumen del entorno de un mundo. Atributos: relieve característico, zona de contacto, horizonte, cielo (heredado de la v1), propiedades de luz ambiental y difusión atmosférica.
- **Sonda (representación visual)**: forma con volumen de la sonda de la v1; refleja la luz y el tinte del cielo, proyecta sombra y muestra el estado (intacta, aterrizada, destruida). Su posición proviene exclusivamente del estado físico de la v1.
- **Luz solar**: fuente de iluminación direccional cuya altura y dirección provienen de Hora Solar (o de la posición inicial durante el descenso). Atributos: dirección, intensidad, color según el mundo y la altura solar, nitidez de sombra.
- **Sombra proyectada**: proyección de la sonda y del relieve sobre el terreno; su longitud y dirección dependen de la luz solar.
- **Cámara**: punto de vista del usuario sobre la escena. Modos: seguimiento lateral fijo (descenso y resultado fallido) y giro libre de 360° alrededor de la nave (Hora Solar tras un éxito).
- **Cabina**: capa plana superpuesta con la telemetría y controles de la v1, independiente de la escena; incluye el selector de calidad visual.
- **Nivel de calidad visual**: preferencia del usuario para la sesión en curso. Valores: «Alta» (por defecto) y «Básica». Solo afecta al detalle de la presentación (FR-022).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: En 100 % de los perfiles de pilotaje de referencia (al menos 5 por mundo, incluyendo contactos a 2,0 y 2,1 m/s), la v2 produce el mismo resultado, velocidad de contacto y combustible restante que la v1.
- **SC-002**: En una prueba con usuarios, al menos el 80 % califica la calidad visual de la v2 como claramente superior a la de la v1 (4 o 5 en una escala de 5).
- **SC-003**: Al menos el 85 % de los observadores identifica correctamente el mundo mostrado solo a partir de una captura del ocaso con la nave en primer plano (sin cabina visible).
- **SC-004**: Con el sol a 45° y a 10° de altura, la longitud de sombra medida en la escena se desvía como máximo un 10 % de la longitud esperada por geometría solar.
- **SC-005**: La escena se percibe fluida (al menos 30 imágenes por segundo) durante el descenso y Hora Solar: en «Alta» en un portátil de gama media actual, y en «Básica» en un móvil de gama media actual.
- **SC-010**: El 100 % de los perfiles de pilotaje de referencia produce el mismo resultado en «Alta» y en «Básica», incluso cambiando de nivel a mitad del descenso.
- **SC-006**: Desde que se elige un mundo, la escena está lista para iniciar el descenso en menos de 5 segundos (mismo objetivo que la v1).
- **SC-007**: En el 100 % de las capturas de revisión, la cabina conserva idéntica posición y tamaño y ningún elemento de la escena contiene colores de la paleta Weincode.
- **SC-008**: Al menos el 70 % de los usuarios de prueba sigue logrando su primer aterrizaje exitoso en 5 intentos o menos (la mejora visual no empeora la jugabilidad respecto a la v1).
- **SC-009**: El ciclo completo funciona con la red desconectada tras la apertura inicial.

## Assumptions

- **Cambio solo de presentación**: la física sigue siendo unidimensional (vertical); el volumen, la perspectiva, la iluminación y las sombras son consecuencia del estado físico de la v1, nunca causa de cambios en él.
- **Sol durante el descenso**: durante el descenso el sol permanece en la posición alta inicial de la v1; las sombras dinámicas dependientes de la hora solar solo se manipulan en Hora Solar tras un éxito.
- **Geometría de sombras**: la longitud esperada de una sombra sobre terreno llano es altura / tangente(altura solar); sobre relieve irregular se acepta la deformación natural de la sombra.
- **Referencias científicas**: los tintes de luz y reflejo reutilizan las referencias documentadas en la v1 para cada mundo; no se requiere investigación óptica nueva salvo para validar la nitidez de sombras por mundo.
- **Rotación de la sonda**: la sonda mantiene su orientación vertical durante todo el descenso y tras el contacto; la actitud y el vuelco siguen fuera de alcance (FR-012).
- **Plataformas**: misma plataforma objetivo que la v1 (navegador de escritorio y móvil, una sola pantalla), idioma español.
- **Fuera de alcance v2**: vuelco o inclinación de la sonda por el terreno, movimiento lateral, viento, nuevos mundos, sonido, realidad virtual, puntuaciones, cambios en constantes, umbrales o reglas de mérito.
