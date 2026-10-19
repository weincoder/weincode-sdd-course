<!--
Sync Impact Report
- Version change: 1.0.0 → 1.1.0 (MINOR: expansión material de Restricciones del Producto;
  ningún principio se elimina ni se redefine de forma incompatible)
- Modified principles:
  - III. Identidad Cromática Weincode en Cabina y Telemetría (aclarado: la paleta no puede
    teñir la escena 3D — cielo, terreno, iluminación)
- Modified sections:
  - Restricciones del Producto: Artefacto Principal 2D → 3D; Dependencias amplía permiso a
    una librería de renderizado 3D empaquetada localmente (no de física)
- Added sections: Ninguna
- Removed sections: Ninguna
- Motivo: demo más vistosa para la serie de YouTube del curso SDD
- Templates requiring updates:
  - ✅ .specify/templates/plan-template.md (gate "Restricciones del Producto" actualizado a 3D)
  - ✅ .specify/templates/spec-template.md (Reviewed; sin cambios)
  - ✅ .specify/templates/tasks-template.md (Reviewed; sin cambios)
  - ✅ .specify/templates/checklist-template.md (Reviewed; sin cambios)
  - ✅ README.md (Reviewed; sin referencias a 2D)
  - ✅ specs/001-planetary-lander-sunset/spec.md (alineada a 3D)
- Follow-up TODOs: Aprobación formal de la tríada de gobierno (PO, Arquitecto Principal,
  Líder de Negocio) pendiente de registrar
-->

# WeinSolar Constitution

**Producto**: WeinSolar es un simulador interactivo de descenso planetario y observación
crepuscular donde el usuario controla el aterrizaje de una sonda espacial en distintos
cuerpos del sistema solar (Tierra, Marte, Luna, Titán), experimentando sus fuerzas
gravitatorias y resistencias atmosféricas reales, y desbloqueando al aterrizar con éxito
una visualización del anochecer fiel a la dispersión óptica de cada mundo.

**Usuarios Objetivo**: Entusiastas de la astronomía, estudiantes y desarrolladores
curiosos por experimentar contrastes astrofísicos y ópticos entre distintos mundos del
sistema solar.

## Core Principles

### I. Fidelidad Astrofísica [NO NEGOCIABLE]

- Toda constante de gravedad, densidad atmosférica y transición cromática del cielo
  durante el anochecer MUST corresponder a datos científicos reales documentados para
  cada planeta o luna (Tierra, Marte, Luna, Titán).
- Queda estrictamente PROHIBIDO inventar físicas arbitrarias o colores de ocaso falsos
  para facilitar el juego o decorar la interfaz.
- **Justificación**: El valor educativo y demostrativo de WeinSolar reside en el
  contraste astrofísico y óptico auténtico entre mundos; alterar los datos científicos
  destruye el propósito central del simulador.

### II. Consecuencia del Impacto y Recompensa Crepuscular [NO NEGOCIABLE]

- Si la velocidad vertical u horizontal al tocar la superficie supera el umbral de
  tolerancia estructural de la sonda, el intento MUST declararse inmediatamente como
  misión fallida.
- Ante una misión fallida, el sistema MUST bloquear por completo el acceso al evento
  visual de anochecer.
- **Justificación**: La observación crepuscular constituye la recompensa directa por
  dominar las condiciones físicas de descenso de cada cuerpo celeste; permitir el acceso
  tras un impacto inválido elimina el bucle de aprendizaje y mérito de la simulación.

### III. Identidad Cromática Weincode en Cabina y Telemetría

- Todo elemento de la interfaz de cabina, controles, selectores y telemetría (HUD) MUST
  usar exclusivamente la paleta oficial de Weincode:
  - Índigo Profundo (`#18084D`)
  - Violeta Eléctrico (`#5236FF`)
  - Lavanda Suave (`#A599FF`)
  - Blanco (`#FFFFFF`)
- Queda estrictamente PROHIBIDO que esta paleta tiña, contamine o altere el lienzo de
  simulación atmosférica del planeta.
- En la escena 3D, la paleta MUST limitarse a la capa de cabina/HUD y controles; el cielo,
  el terreno, la sonda y la iluminación de la escena MUST NOT usar ni reflejar estos colores.
- **Justificación**: Garantiza el reconocimiento visual de la marca Weincode en los
  instrumentos de control mientras preserva intacta la pureza óptica del fenómeno
  crepuscular exigida por el Principio I.

### IV. Autonomía en Cliente y Cero Dependencia Externa

- El simulador MUST ejecutarse de forma 100% autocontenida en el dispositivo del usuario
  desde su apertura.
- Queda estrictamente PROHIBIDO exigir cuentas de usuario, bases de datos remotas o
  llamadas de red en tiempo de ejecución para completar el ciclo de descenso y anochecer.
- **Justificación**: Asegura disponibilidad inmediata, latencia cero durante el bucle de
  simulación física y portabilidad total entre implementaciones cliente sin fricción ni
  infraestructura externa.

## Restricciones del Producto

- **Artefacto Principal**: Simulador interactivo 3D de física de descenso y renderizado
  óptico crepuscular.
- **Regla de Cambio Tecnológico**: Se trabaja sobre el stack existente en cada
  repositorio de implementación (declarado en el archivo de contexto del agente);
  cambiar la tecnología base de un repositorio MUST requerir una enmienda constitucional
  aprobada.
- **Dependencias**: Queda PROHIBIDO añadir librerías externas para cálculos físicos que
  puedan resolverse con fórmulas cinemáticas estándar dentro del ciclo nativo de
  actualización.
- **Renderizado 3D**: Se permite una única librería de renderizado 3D (no de física). MUST
  empaquetarse localmente con la aplicación y MUST NOT cargarse por red en tiempo de
  ejecución (Principio IV).

## Flujo de Trabajo y Compuertas de Calidad

1. **Compuerta de Especificación**: Ninguna `pre-spec.md` ni `spec.md` MUST avanzar si
   contradice cualquiera de los principios de esta constitución.
2. **Compuerta de Implementación**: Queda PROHIBIDO escribir código de simulación sin
   una `spec.md` aprobada que defina explícitamente las constantes planetarias y los
   criterios de aceptación observables.
3. **Compuerta de Verificación Visual**: Todo entregable MUST verificar visualmente los
   umbrales de impacto, la fidelidad cromática del ocaso de cada planeta y el uso
   estricto de los códigos `#18084D`, `#5236FF`, `#A599FF` y `#FFFFFF` en el HUD.

## Governance

- **Autoridad de Enmiendas**: Esta constitución prevalece sobre cualquier otra práctica
  o decisión técnica. Cualquier adición, modificación o eliminación de principios MUST
  contar con la aprobación conjunta de la tríada de gobierno: **Product Owner (PO),
  Arquitecto Principal y Líder de Negocio**, registrando siempre el correspondiente
  *Sync Impact Report*.
- **Política de Versionado**: Se aplica versionado semántico (`MAJOR.MINOR.PATCH`):
  - `MAJOR`: Eliminación o redefinición incompatible de principios o reglas de gobierno.
  - `MINOR`: Adición de nuevos principios, secciones o expansión material de reglas.
  - `PATCH`: Clarificaciones de redacción, correcciones tipográficas o refinamientos sin
    cambio semántico.
- **Verificación de Cumplimiento**: El Arquitecto Principal y el Product Owner (PO) MUST
  auditar explícitamente cada especificación (`pre-spec.md`, `spec.md`), plan y Pull
  Request contra los Principios I al IV antes de autorizar cualquier fusión.

**Version**: 1.1.0 | **Ratified**: 2026-10-17 | **Last Amended**: 2026-10-18
