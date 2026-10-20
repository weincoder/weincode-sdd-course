<div align="center">

# 🪐 WeinSolar — Curso de Spec-Driven Development (SDD)

**De picar código a orquestar soluciones** · *From writing code to orchestrating solutions*

[![Weincode](https://img.shields.io/badge/Weincode-SDD_Course-5236FF?style=for-the-badge&labelColor=18084D)](https://youtube.com/@weincode)
[![Angular](https://img.shields.io/badge/Angular-DD0031?style=for-the-badge&logo=angular&logoColor=white)](#)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](#)
[![Spec-Driven](https://img.shields.io/badge/Architecture-Spec--Driven-A599FF?style=for-the-badge&labelColor=18084D)](#)

**[🇪🇸 Español](#-español)** | **[🇺🇸 English](#-english)**

</div>

---

## 🇪🇸 Español

Bienvenido al repositorio oficial del **Curso de Spec-Driven Development (SDD)** de **Weincode**.

En la era de la Inteligencia Artificial generativa, el valor del desarrollador ya no radica en ser un traductor de sintaxis, sino en su capacidad de abstracción, gobierno y arquitectura. Este repositorio demuestra cómo diseñar un producto desde sus reglas no negociables y especificaciones funcionales (**100% agnósticas a la tecnología**) para que luego los agentes de código construyan la solución exacta en múltiples plataformas sin alucinaciones.

### 🚀 El Proyecto Demostrativo: WeinSolar

**WeinSolar** es un simulador interactivo de descenso planetario y observación crepuscular. Los usuarios experimentan fuerzas gravitatorias, resistencias atmosféricas y fenómenos ópticos de anochecer fieles a cada cuerpo del sistema solar (Tierra, Marte, Luna, Titán), manteniendo la identidad cromática de Weincode (`#18084D`, `#5236FF`, `#A599FF`) en su telemetría y cabina.

Lo más potente de este repositorio es que **una única especificación (`spec.md`) gobierna dos implementaciones completamente distintas**:

| Plataforma | Stack Tecnológico | Ubicación |
| :--- | :--- | :--- |
| 🅰️ **Aplicación Web** | **Angular 21** (Signals, Standalone, `angular-three` + `Three.js` WebGL2) | `/apps/weinsolar-angular` |
| 💙 **Aplicación Móvil / Multiplataforma** | **Flutter 3.41** (Material 3, `flutter_scene` + Impeller GPU 3D) | `/apps/weinsolar-flutter` |

### 📂 Estructura del Repositorio

```text
weinsolar-sdd/
├── .specify/                  # Capa pura de SDD (100% libre de stack tecnológico)
│   ├── constitution.md        # Principios no negociables y gobierno del proyecto
│   ├── pre-spec.md            # Fase de descubrimiento, supuestos y validación
│   └── spec.md                # Especificación funcional definitiva y trazabilidad
├── prompts/
│   └── arquitecto-sdd-gem.md  # System Prompt completo para tu Gema/Agente SDD
└── apps/
    ├── weinsolar-angular/     # Implementación en Angular (con su propio AGENTS.md)
    └── weinsolar-flutter/     # Implementación en Flutter (con su propio AGENTS.md)
```

### 🧠 Las 4 Fases del Flujo SDD

1. **Constitución (`constitution.md`):** Define las leyes inmutables del producto, restricciones y gobierno antes de hablar de funcionalidades.
2. **Pre-Spec (`pre-spec.md`):** Descubrimiento socrático de negocio. Separa hechos de supuestos (`[SUPUESTO]`), resuelve preguntas evaluando *trade-offs* y delimita el fuera de alcance.
3. **Spec (`spec.md`):** El contrato funcional definitivo con Historias de Usuario (`HU`), Requisitos Funcionales (`RF`), Reglas de Negocio (`RN`), Criterios de Aceptación (`CA`), Casos Límite (`CL`) y Matrices de Trazabilidad.
4. **Orquestación de Código:** Entrega de los artefactos `.md` junto con el contexto técnico (`AGENTS.md`) al agente de desarrollo para su ejecución autónoma y verificación.

---

## 🇺🇸 English

Welcome to the official repository for **Weincode's Spec-Driven Development (SDD) Course**.

In the era of Generative AI, a developer's true value no longer lies in manually typing syntax, but in system abstraction, governance, and software architecture. This repository demonstrates how to design a software product starting from its non-negotiable principles and functional specifications (**100% technology-agnostic**), enabling AI coding agents to accurately build the exact same solution across multiple platforms without hallucinations.

### 🚀 The Showcase Project: WeinSolar

**WeinSolar** is an interactive planetary landing and twilight observation simulator. Users experience real gravitational forces, atmospheric drag, and optical sunset phenomena across different Solar System bodies (Earth, Mars, Moon, Titan), wrapped in Weincode's signature cockpit telemetry UI (`#18084D`, `#5236FF`, `#A599FF`).

The core highlight of this repository is that **a single functional specification (`spec.md`) drives two completely different tech stacks**:

| Platform | Tech Stack | Path |
| :--- | :--- | :--- |
| 🅰️ **Web Application** | **Angular 21** (Signals, Standalone, `angular-three` + `Three.js` WebGL2) | `/apps/weinsolar-angular` |
| 💙 **Mobile / Cross-Platform** | **Flutter 3.41** (Material 3, `flutter_scene` + Impeller GPU 3D) | `/apps/weinsolar-flutter` |

### 📂 Repository Structure

```text
weinsolar-sdd/
├── .specify/                  # Pure SDD Layer (100% tech-stack agnostic)
│   ├── constitution.md        # Non-negotiable principles and project governance
│   ├── pre-spec.md            # Discovery phase, assumptions, and validation package
│   └── spec.md                # Final functional specification & traceability matrices
├── prompts/
│   └── arquitecto-sdd-gem.md  # Full System Prompt to configure your SDD Architect Gem
└── apps/
    ├── weinsolar-angular/     # Angular implementation (guided by local AGENTS.md)
    └── weinsolar-flutter/     # Flutter implementation (guided by local AGENTS.md)
```

### 🧠 The 4-Stage SDD Workflow

1. **Constitution (`constitution.md`):** Establishes the immutable laws, product constraints, and governance before discussing features.
2. **Pre-Spec (`pre-spec.md`):** Business discovery phase. Separates verified facts from assumptions, evaluates trade-offs, and locks down out-of-scope boundaries.
3. **Spec (`spec.md`):** The definitive functional contract containing User Stories, Functional Requirements, Business Rules, Acceptance Criteria, Edge Cases, and Traceability Matrices.
4. **Code Orchestration:** Handing over the `.md` artifacts alongside a lightweight tech-context file (`AGENTS.md`) to the coding agent for autonomous implementation and testing.

---

<div align="center">

### 🦉 Creado por / Created by
**Daniel Herrera Sánchez** — [Weincode](https://youtube.com/@weincode)

</div>
