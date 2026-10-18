---
description: Guía práctica para implementar Arquitectura Limpia en Angular con standalone components y nueva sintaxis de control de flujo.
applyTo: '**/*.ts, **/*.js'
---

🏗️ Guía de Arquitectura Limpia en Angular 17+
Índice
Principios Fundamentales
Estructura de Carpetas
Capa de Dominio
Capa de Infraestructura
Capa de UI (Presentación)
Capa de Configuración
Inversión de Dependencias
Paso a Paso: Agregar una Nueva Entidad
Buenas Prácticas
Anti-patrones a Evitar
1. Principios Fundamentales
La Arquitectura Limpia (Clean Architecture) se basa en los principios SOLID y busca separar las responsabilidades del software en capas independientes.

Regla de Dependencia
Las dependencias siempre apuntan hacia adentro. Las capas externas conocen a las internas, pero NUNCA al revés.

┌─────────────────────────────────────────────────────┐
│                     UI / Presentación                │  ← Capa más externa
│  ┌─────────────────────────────────────────────────┐│
│  │              Infraestructura                     ││
│  │  ┌─────────────────────────────────────────────┐││
│  │  │              Dominio (Núcleo)               │││  ← Capa más interna
│  │  │  • Modelos/Entidades                        │││
│  │  │  • Gateways (abstracciones)                 │││
│  │  │  • Casos de Uso                             │││
│  │  └─────────────────────────────────────────────┘││
│  └─────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────┘
Principios Clave
Principio	Descripción
Independencia del Framework	El dominio no conoce Angular, ni HttpClient, ni ninguna librería externa
Testeable	La lógica de negocio se puede probar sin UI, base de datos, ni servidor
Independencia de la UI	La UI puede cambiar sin modificar el resto del sistema
Independencia de la base de datos/API	Se puede cambiar la fuente de datos sin afectar la lógica de negocio
Inversión de Dependencias	Las capas de alto nivel no dependen de las de bajo nivel; ambas dependen de abstracciones
2. Estructura de Carpetas
src/
├── app/
│   ├── config/                          # ⚙️ Configuración de la aplicación
│   │   ├── app.config.ts                # Providers, inyección de dependencias
│   │   └── app.routes.ts                # Definición de rutas
│   │
│   ├── domain/                          # 🧠 NÚCLEO - Lógica de Negocio Pura
│   │   ├── models/                      # Entidades del dominio
│   │   │   └── [Entidad]/
│   │   │       ├── entidad.ts           # Modelo de datos
│   │   │       └── gateway/
│   │   │           └── entidad-gateway.ts  # Contrato abstracto (puerto)
│   │   └── usecase/                     # Casos de uso
│   │       └── get-entidad-use-case.ts
│   │
│   ├── infraestructure/                 # 🔌 Implementaciones Concretas
│   │   ├── driven-adapter/              # Adaptadores (implementan los gateways)
│   │   │   └── entidad-api/
│   │   │       ├── entidad-api.service.ts
│   │   │       └── entidad-api.service.spec.ts
│   │   └── helpers/                     # Utilidades de infraestructura
│   │       └── maps/                    # Mappers de datos
│   │           ├── common/
│   │           │   └── maps.ts          # Mapper abstracto genérico
│   │           └── entidad_mapper.ts
│   │
│   └── UI/                              # 🎨 Capa de Presentación
│       ├── ds/                          # Design System
│       │   └── atoms/                   # Componentes atómicos reutilizables
│       │       └── [componente]/
│       ├── main/                        # Componente raíz
│       │   └── main.component.ts
│       └── pages/                       # Páginas/Vistas
│           └── [página]/
│               └── página.component.ts
│
├── assets/                              # Recursos estáticos
├── index.html
├── main.ts
└── styles.scss
3. Capa de Dominio
La capa de dominio es el corazón de la aplicación. No debe tener NINGUNA dependencia con frameworks externos (Angular, RxJS es aceptable por ser la base reactiva).

3.1 Modelo (Entidad)
El modelo representa la estructura de datos pura del dominio.

// domain/models/Album/album.ts

export class Album {
    userId!  : number;
    id!      : number;
    title!   : string;
}
Reglas: - ✅ Solo propiedades y métodos propios del dominio - ✅ Puede tener validaciones internas - ❌ NO decoradores de Angular (@Injectable, @Component, etc.) - ❌ NO dependencias de infraestructura

3.2 Gateway (Puerto / Contrato Abstracto)
El gateway define el contrato que cualquier implementación debe cumplir. Es una clase abstracta que actúa como interfaz inyectable.

// domain/models/Album/gateway/album-gateway.ts

import { Observable } from 'rxjs';
import { Album } from '../album';

export abstract class AlbumGateway {
    abstract getByID(id: String): Observable<Album>;
    abstract getAll(): Observable<Array<Album>>;
    abstract saveNew(_alb: Album): Observable<void>;
}
¿Por qué clase abstracta y no interfaz?

En Angular, las interfaces no pueden usarse como tokens de inyección de dependencias. Las clases abstractas sí, lo que permite usar el sistema DI de Angular para resolver implementaciones en tiempo de ejecución.

Reglas: - ✅ Define TODOS los métodos que la infraestructura debe implementar - ✅ Usa tipos del dominio (Album, no any) - ✅ Retorna Observable<T> para operaciones asíncronas - ❌ NO tiene implementación (solo firmas abstractas) - ❌ NO conoce HttpClient, localStorage, ni ninguna tecnología concreta

3.3 Caso de Uso (Use Case)
Los casos de uso encapsulan la lógica de negocio específica de una operación.

// domain/usecase/get-album-use-case.ts

import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { Album } from '../models/Album/album';
import { AlbumGateway } from '../models/Album/gateway/album-gateway';

@Injectable({
  providedIn: 'root'
})
export class GetAlbumUseCases {
  constructor(private _albumGateWay: AlbumGateway) {}

  getAlbumById(id: String): Observable<Album> {
    return this._albumGateWay.getByID(id);
  }

  getAllAlbum(): Observable<Array<Album>> {
    return this._albumGateWay.getAll();
  }
}
Reglas: - ✅ Inyecta el Gateway abstracto, NUNCA la implementación concreta - ✅ Contiene lógica de negocio (transformaciones, validaciones, combinaciones) - ✅ Cada caso de uso debe tener una responsabilidad clara - ❌ NO accede directamente a APIs, DB, o servicios externos - ❌ NO conoce la UI

4. Capa de Infraestructura
La infraestructura contiene las implementaciones concretas de los contratos definidos en el dominio.

4.1 Driven Adapter (Adaptador)
El adaptador implementa el gateway usando una tecnología concreta (HTTP, WebSocket, localStorage, etc.).

// infraestructure/driven-adapter/album-api/album-api.service.ts

import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { AlbumGateway } from '../../../domain/models/Album/gateway/album-gateway';
import { Album } from '../../../domain/models/Album/album';
import { Observable, delay } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class AlbumApiService extends AlbumGateway {
  private _url = 'https://jsonplaceholder.typicode.com/albums/';

  constructor(private http: HttpClient) { super(); }

  getByID(id: String): Observable<Album> {
    return this.http.get<Album>(this._url + id).pipe(delay(3000));
  }

  getAll(): Observable<Album[]> {
    return this.http.get<Array<Album>>(this._url);
  }

  saveNew(_alb: Album): Observable<void> {
    throw new Error('Method not implemented.');
  }
}
Se pueden tener múltiples implementaciones del mismo gateway:

// album-api-without-delay.service.ts - Implementación alternativa SIN delay

export class AlbumApiServiceWithoutDelay extends AlbumGateway {
  // Misma implementación pero sin delay(3000)
}
Reglas: - ✅ Extiende (extends) el gateway abstracto del dominio - ✅ Implementa TODOS los métodos abstractos - ✅ Aquí sí se usa HttpClient, localStorage, WebSocket, etc. - ✅ Puede tener lógica de mapeo de datos (API → Dominio) - ❌ NO contiene lógica de negocio

4.2 Helpers / Mappers
Los mappers transforman datos externos (API responses) al formato del dominio.

// infraestructure/helpers/maps/common/maps.ts

export abstract class Mapper<I> {
    abstract fromMap(obj: any): I;
}
// infraestructure/helpers/maps/album_mapper.ts
// Implementar el mapper concreto para la entidad

import { Mapper } from './common/maps';
import { Album } from '../../../domain/models/Album/album';

export class AlbumMapper extends Mapper<Album> {
    fromMap(obj: any): Album {
        const album = new Album();
        album.id = obj.id;
        album.userId = obj.userId;
        album.title = obj.title;
        return album;
    }
}
5. Capa de UI (Presentación)
La capa de UI se encarga exclusivamente de la presentación y la interacción con el usuario.

5.1 Design System (Componentes Reutilizables)
Organiza componentes visuales reutilizables usando Atomic Design:

UI/ds/
├── atoms/          # Componentes básicos (botones, inputs, spinners)
├── molecules/      # Combinaciones de átomos
├── organisms/      # Secciones complejas
└── templates/      # Layouts de página
// UI/ds/atoms/circular-progress/circular-progress.component.ts

@Component({
  selector: 'app-circular-progress',
  standalone: true,
  imports: [],
  templateUrl: './circular-progress.component.html',
  styleUrl: './circular-progress.component.scss'
})
export class CircularProgressComponent { }
5.2 Pages (Páginas)
Las páginas son componentes que representan vistas completas. Inyectan Casos de Uso, NUNCA servicios de infraestructura directamente.

// UI/pages/album/album.component.ts

import { Component, OnInit } from '@angular/core';
import { GetAlbumUseCases } from '../../../domain/usecase/get-album-use-case';
import { Album } from '../../../domain/models/Album/album';
import { Observable } from 'rxjs';

@Component({
  selector: 'app-album',
  standalone: true,
  imports: [CircularProgressComponent],
  templateUrl: './album.component.html',
  styleUrl: './album.component.scss'
})
export class AlbumComponent implements OnInit {
  constructor(private _getAlbumUseCase: GetAlbumUseCases) { }

  response$: Observable<Album> | undefined;
  datos?: Album;

  ngOnInit(): void {
    this.response$ = this._getAlbumUseCase.getAlbumById('20');
    this.response$.subscribe(
      (data: Album) => {
        this.datos = data;
      }
    );
  }
}
<!-- UI/pages/album/album.component.html -->
<div class="tarjeta">
    <h1>Titulo Album :</h1>
    @if (!datos?.title) {
        <app-circular-progress></app-circular-progress>
    }
    <h3>{{datos?.title}}</h3>
</div>
Reglas: - ✅ Inyecta Casos de Uso del dominio - ✅ Usa componentes del Design System - ✅ Usa la nueva sintaxis de control de flujo de Angular 17+ (@if, @for) - ❌ NO inyecta servicios de infraestructura directamente - ❌ NO contiene lógica de negocio

5.3 Main Component (Raíz)
// UI/main/main.component.ts

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, AlbumComponent],
  templateUrl: './main.component.html',
  styleUrl: './main.component.scss'
})
export class MainComponent { }
6. Capa de Configuración
Aquí se conectan todas las piezas mediante la Inversión de Dependencias.

6.1 App Config (Inyección de Dependencias)
// config/app.config.ts

import { ApplicationConfig } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withFetch } from '@angular/common/http';
import { routes } from './app.routes';
import { AlbumGateway } from '../domain/models/Album/gateway/album-gateway';
import { AlbumApiService } from '../infraestructure/driven-adapter/album-api/album-api.service';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideHttpClient(withFetch()),
    // 🔑 AQUÍ se conecta la abstracción con la implementación concreta
    { provide: AlbumGateway, useClass: AlbumApiService },
  ]
};
Este es el punto clave de la inversión de dependencias: - provide: AlbumGateway → La abstracción (token de inyección) - useClass: AlbumApiService → La implementación concreta

Para cambiar la implementación, solo se modifica esta línea:

// Cambiar de API con delay a API sin delay:
{ provide: AlbumGateway, useClass: AlbumApiServiceWithoutDelay },
7. Inversión de Dependencias
Flujo de Dependencias
┌──────────┐     inyecta      ┌──────────────┐     inyecta      ┌──────────────┐
│   UI     │ ──────────────► │  Use Case    │ ──────────────► │   Gateway    │
│ (Page)   │                  │              │                  │  (Abstracto) │
└──────────┘                  └──────────────┘                  └──────┬───────┘
                                                                       │
                                                                       │ extends
                                                                       │
                                                               ┌───────▼───────┐
                                                               │   Adapter     │
                                                               │  (Concreto)   │
                                                               └───────────────┘
                                                                       │
                                                            ┌──────────┼──────────┐
                                                            │          │          │
                                                      ┌─────▼──┐ ┌────▼───┐ ┌───▼────┐
                                                      │HTTP API│ │ Local  │ │ Mock   │
                                                      │        │ │Storage │ │Service │
                                                      └────────┘ └────────┘ └────────┘
Conexión en app.config.ts
providers: [
    //  Token Abstracto        →   Implementación Concreta
    { provide: AlbumGateway,   useClass: AlbumApiService },
]
8. Paso a Paso: Agregar una Nueva Entidad
Ejemplo: Agregar la entidad User a la aplicación.

Paso 1️⃣ — Crear el Modelo
mkdir -p src/app/domain/models/User/gateway
// domain/models/User/user.ts
export class User {
    id!: number;
    name!: string;
    email!: string;
    username!: string;
}
Paso 2️⃣ — Crear el Gateway (Contrato)
// domain/models/User/gateway/user-gateway.ts
import { Observable } from 'rxjs';
import { User } from '../user';

export abstract class UserGateway {
    abstract getByID(id: number): Observable<User>;
    abstract getAll(): Observable<Array<User>>;
    abstract save(user: User): Observable<User>;
    abstract delete(id: number): Observable<void>;
}
Paso 3️⃣ — Crear el Caso de Uso
// domain/usecase/get-user-use-case.ts
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { User } from '../models/User/user';
import { UserGateway } from '../models/User/gateway/user-gateway';

@Injectable({ providedIn: 'root' })
export class GetUserUseCases {
    constructor(private _userGateway: UserGateway) {}

    getUserById(id: number): Observable<User> {
        return this._userGateway.getByID(id);
    }

    getAllUsers(): Observable<Array<User>> {
        return this._userGateway.getAll();
    }
}
Paso 4️⃣ — Crear el Adaptador (Infraestructura)
mkdir -p src/app/infraestructure/driven-adapter/user-api
// infraestructure/driven-adapter/user-api/user-api.service.ts
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { UserGateway } from '../../../domain/models/User/gateway/user-gateway';
import { User } from '../../../domain/models/User/user';

@Injectable({ providedIn: 'root' })
export class UserApiService extends UserGateway {
    private _url = 'https://jsonplaceholder.typicode.com/users/';

    constructor(private http: HttpClient) { super(); }

    getByID(id: number): Observable<User> {
        return this.http.get<User>(this._url + id);
    }

    getAll(): Observable<User[]> {
        return this.http.get<Array<User>>(this._url);
    }

    save(user: User): Observable<User> {
        return this.http.post<User>(this._url, user);
    }

    delete(id: number): Observable<void> {
        return this.http.delete<void>(this._url + id);
    }
}
Paso 5️⃣ — Registrar la Inyección de Dependencias
// config/app.config.ts
import { UserGateway } from '../domain/models/User/gateway/user-gateway';
import { UserApiService } from '../infraestructure/driven-adapter/user-api/user-api.service';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideHttpClient(withFetch()),
    { provide: AlbumGateway, useClass: AlbumApiService },
    { provide: UserGateway, useClass: UserApiService },  // ← NUEVO
  ]
};
Paso 6️⃣ — Crear la Página (UI)
mkdir -p src/app/UI/pages/user
// UI/pages/user/user.component.ts
import { Component, OnInit } from '@angular/core';
import { GetUserUseCases } from '../../../domain/usecase/get-user-use-case';
import { User } from '../../../domain/models/User/user';

@Component({
  selector: 'app-user',
  standalone: true,
  imports: [],
  template: `
    <div class="tarjeta">
      <h1>User</h1>
      @if (user) {
        <p>{{ user.name }}</p>
        <p>{{ user.email }}</p>
      }
    </div>
  `
})
export class UserComponent implements OnInit {
  constructor(private _getUserUseCase: GetUserUseCases) {}
  user?: User;

  ngOnInit(): void {
    this._getUserUseCase.getUserById(1).subscribe(
      (data: User) => this.user = data
    );
  }
}
9. Buenas Prácticas
✅ Hacer
Práctica	Razón
Un caso de uso por responsabilidad	Principio de Responsabilidad Única
Usar Observable en gateways	Consistencia reactiva con Angular
Clases abstractas para gateways	Permite inyección de dependencias en Angular
Múltiples implementaciones por gateway	Flexibilidad (con/sin delay, mock, cache)
Standalone components	Estándar Angular 17+
Nueva sintaxis @if, @for	Control de flujo moderno Angular 17+
Mappers en infraestructura	Desacopla formato API del modelo de dominio
Tests unitarios por capa	Cada capa se testea independientemente
✅ Convenciones de Nombrado
Modelo:     album.ts              → export class Album
Gateway:    album-gateway.ts      → export abstract class AlbumGateway
Use Case:   get-album-use-case.ts → export class GetAlbumUseCases
Adapter:    album-api.service.ts  → export class AlbumApiService
Mapper:     album_mapper.ts       → export class AlbumMapper
Page:       album.component.ts    → export class AlbumComponent
✅ Testing por Capas
Dominio:          Mock del gateway → Testea caso de uso
Infraestructura:  HttpTestingController → Testea adaptador
UI:               Mock del caso de uso → Testea componente
10. Anti-patrones a Evitar
❌ No Hacer
Anti-patrón	Problema	Solución
Inyectar AlbumApiService en un componente	Acoplamiento directo a infraestructura	Inyectar GetAlbumUseCases
Lógica de negocio en componentes	Violación de SRP, difícil de testear	Mover al caso de uso
HttpClient en un caso de uso	El dominio conoce infraestructura	Usar el gateway abstracto
Interfaces en vez de clases abstractas para DI	Angular no puede inyectar interfaces	Usar abstract class
Modelos con decoradores Angular	Acoplamiento del dominio al framework	Modelos puros (POJO/POTS)
Un solo caso de uso gigante	Violación de SRP	Dividir por responsabilidad
Lógica de mapeo en componentes	Responsabilidad mal ubicada	Usar Mappers en infraestructura
Resumen Visual
                    ┌─────────────────┐
                    │   app.config.ts │  ← Conecta abstracciones con implementaciones
                    │   (providers)   │
                    └────────┬────────┘
                             │
           ┌─────────────────┼─────────────────┐
           │                 │                  │
    ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐
    │   DOMINIO   │   │  INFRA      │   │     UI      │
    │             │   │             │   │             │
    │ • Modelos   │   │ • Adapters  │   │ • Pages     │
    │ • Gateways  │◄──│   (extends) │   │ • DS        │
    │ • UseCases  │   │ • Mappers   │   │ • Main      │
    └─────────────┘   └─────────────┘   └─────────────┘
          ▲                                    │
          │          inyecta UseCase            │
          └────────────────────────────────────┘

    📌 Dirección de dependencia: UI → Dominio ← Infraestructura
Con standalone components, nueva sintaxis de control de flujo (@if, @for), y configuración funcional (ApplicationConfig + provideRouter + provideHttpClient).