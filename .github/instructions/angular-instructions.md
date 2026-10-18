---
description: Instrucciones para generar código Angular (standalone, signals, control de flujo nativo) siguiendo Clean Architecture y SOLID.
applyTo: '**/*.ts,**/*.html,**/*.scss'
---

# 🤖 LLM INSTRUCTIONS: ANGULAR CLEAN ARCHITECTURE

## 🌍 CONTEXTO DEL SISTEMA

Actúa como Tech Lead y Senior Angular Developer. Genera código respetando estrictamente Clean Architecture y SOLID. No te saltes capas ni mezcles responsabilidades. Usa siempre las APIs actuales y recomendadas de la versión de Angular instalada en el repositorio (consulta `package.json`); nunca uses APIs obsoletas.

## 🛑 REGLAS GLOBALES ABSOLUTAS

1. **REGLA DE DEPENDENCIAS:** `UI` e `infraestructure` dependen de `domain`. `domain` NO depende de nadie (ni Angular, ni `HttpClient`, ni librerías externas). Única excepción permitida: `rxjs` para tipos reactivos.
2. **CERO ALUCINACIONES DE PAQUETES:** No añadas dependencias npm salvo petición explícita. Si una librería es necesaria, propónla y espera confirmación.
3. **INVERSIÓN DE DEPENDENCIAS:** La UI inyecta casos de uso; los casos de uso inyectan gateways abstractos; la unión gateway → adaptador se hace SOLO en `config/app.config.ts`.
4. **INYECCIÓN:** Usa `inject()` en campos de clase. No instancies con `new` servicios, adaptadores ni casos de uso.
5. **IDIOMA:** Código (clases, métodos, variables, archivos) en inglés. Textos visibles en la UI en español.
6. **RESTRICCIONES DEL PROYECTO:** Si existe `.specify/memory/constitution.md`, sus reglas prevalecen sobre este archivo (p. ej. prohibición de llamadas de red en tiempo de ejecución → usa adaptadores locales, no HTTP).

## 🧱 ESTÁNDARES DE ANGULAR MODERNO (OBLIGATORIOS)

| Usa siempre | Nunca uses |
|-------------|------------|
| Componentes standalone (sin `NgModule`) | `NgModule` para features nuevas |
| `inject()` | Inyección por constructor en código nuevo |
| `signal()`, `computed()`, `input()`, `output()`, `model()` | `@Input()` / `@Output()` decoradores en código nuevo |
| Control de flujo `@if`, `@for` (con `track`), `@switch`, `@defer` | `*ngIf`, `*ngFor`, `*ngSwitch` |
| `ChangeDetectionStrategy.OnPush` | Detección de cambios por defecto |
| `toSignal()` o `async` pipe para consumir `Observable` | `subscribe()` manual en componentes |
| `takeUntilDestroyed()` si un `subscribe()` es inevitable | Suscripciones sin liberar |
| `ApplicationConfig` + `provideRouter` + `provideHttpClient(withFetch())` | Configuración basada en módulos |
| Tipos estrictos (`string`, `number`, `unknown`) | `any`, `String`, `Number` |
| Rutas con `loadComponent` (lazy) | Importar todas las páginas en la raíz |

## 📁 ESTRUCTURA DE DIRECTORIOS ESTRICTA

```text
src/app/
├── config/
│   ├── app.config.ts              # Providers e inversión de dependencias
│   └── app.routes.ts              # Rutas (lazy con loadComponent)
├── domain/                        # 🧠 Lógica de negocio pura (sin Angular)
│   ├── models/<entity>/
│   │   ├── <entity>.ts            # Modelo / entidad
│   │   └── gateway/<entity>-gateway.ts   # Contrato abstracto (puerto)
│   └── usecase/<action>-<entity>.use-case.ts
├── infraestructure/               # 🔌 Implementaciones concretas
│   ├── driven-adapter/<entity>-<source>/<entity>-<source>.adapter.ts
│   └── helpers/mappers/<entity>.mapper.ts
└── UI/                            # 🎨 Presentación
    ├── ds/{atoms,molecules,organisms,templates}/   # Design System (Atomic Design)
    ├── main/main.component.ts     # Componente raíz
    └── pages/<page>/<page>.component.ts
```

Mantén estos nombres de carpeta tal cual (incluido `infraestructure`), aunque parezcan erratas: son la convención del proyecto.

## 🧩 PLANTILLAS POR CAPA

### 1. Modelo (domain)

```typescript
// domain/models/album/album.ts
export interface Album {
  readonly id: number;
  readonly userId: number;
  readonly title: string;
}
```

- ✅ Solo datos y reglas propias del dominio (validaciones, invariantes, cálculos puros).
- ❌ Sin decoradores de Angular ni imports de infraestructura.

### 2. Gateway / Puerto (domain)

```typescript
// domain/models/album/gateway/album-gateway.ts
import { Observable } from 'rxjs';
import { Album } from '../album';

export abstract class AlbumGateway {
  abstract getById(id: number): Observable<Album>;
  abstract getAll(): Observable<Album[]>;
  abstract save(album: Album): Observable<void>;
}
```

- ✅ Usa `abstract class`, no `interface`: Angular no puede usar interfaces como token de DI.
- ✅ Solo firmas abstractas con tipos del dominio. Operaciones asíncronas → `Observable<T>`.
- ❌ No menciona HTTP, `localStorage` ni ninguna tecnología concreta.

### 3. Caso de uso (domain)

```typescript
// domain/usecase/get-album.use-case.ts
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { Album } from '../models/album/album';
import { AlbumGateway } from '../models/album/gateway/album-gateway';

@Injectable({ providedIn: 'root' })
export class GetAlbumUseCase {
  private readonly albumGateway = inject(AlbumGateway);

  getById(id: number): Observable<Album> {
    return this.albumGateway.getById(id);
  }

  getAll(): Observable<Album[]> {
    return this.albumGateway.getAll();
  }
}
```

- ✅ Inyecta SOLO gateways abstractos. Una responsabilidad por caso de uso.
- ✅ Aquí viven transformaciones, validaciones y combinaciones de negocio.
- ℹ️ `@Injectable` e `inject` son la única concesión al framework en `domain`, necesaria para la DI.

### 4. Adaptador (infraestructure)

```typescript
// infraestructure/driven-adapter/album-api/album-api.adapter.ts
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { AlbumGateway } from '../../../domain/models/album/gateway/album-gateway';
import { Album } from '../../../domain/models/album/album';
import { AlbumMapper } from '../../helpers/mappers/album.mapper';

@Injectable({ providedIn: 'root' })
export class AlbumApiAdapter extends AlbumGateway {
  private readonly http = inject(HttpClient);
  private readonly url = 'https://example.com/albums';

  getById(id: number): Observable<Album> {
    return this.http.get<unknown>(`${this.url}/${id}`).pipe(map(AlbumMapper.fromApi));
  }

  getAll(): Observable<Album[]> {
    return this.http.get<unknown[]>(this.url).pipe(map((items) => items.map(AlbumMapper.fromApi)));
  }

  save(album: Album): Observable<void> {
    return this.http.post<void>(this.url, album);
  }
}
```

- ✅ `extends` el gateway e implementa TODOS sus métodos (nunca `throw new Error('Method not implemented.')`).
- ✅ Puede haber varias implementaciones del mismo gateway (API, local, mock, caché).
- ❌ Sin lógica de negocio: solo acceso a datos y mapeo.

### 5. Mapper (infraestructure)

```typescript
// infraestructure/helpers/mappers/album.mapper.ts
import { Album } from '../../../domain/models/album/album';

export const AlbumMapper = {
  fromApi(raw: unknown): Album {
    const obj = raw as Record<string, unknown>;
    return { id: Number(obj['id']), userId: Number(obj['userId']), title: String(obj['title'] ?? '') };
  },
};
```

- ✅ Recibe `unknown` y devuelve un modelo del dominio. Es el único lugar que conoce el formato externo.

### 6. Página (UI)

```typescript
// UI/pages/album/album.component.ts
import { ChangeDetectionStrategy, Component, inject, input } from '@angular/core';
import { toSignal, toObservable } from '@angular/core/rxjs-interop';
import { switchMap } from 'rxjs';
import { GetAlbumUseCase } from '../../../domain/usecase/get-album.use-case';
import { CircularProgressComponent } from '../../ds/atoms/circular-progress/circular-progress.component';

@Component({
  selector: 'app-album',
  imports: [CircularProgressComponent],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <section class="card">
      <h1>Álbum</h1>
      @if (album(); as album) {
        <h3>{{ album.title }}</h3>
      } @else {
        <app-circular-progress />
      }
    </section>
  `,
})
export class AlbumComponent {
  private readonly getAlbum = inject(GetAlbumUseCase);

  readonly albumId = input.required<number>();
  readonly album = toSignal(toObservable(this.albumId).pipe(switchMap((id) => this.getAlbum.getById(id))));
}
```

- ✅ Inyecta casos de uso, NUNCA adaptadores. Estado con signals; plantillas con `@if` / `@for (...; track ...)`.
- ✅ Los componentes del Design System son presentacionales: reciben `input()` y emiten `output()`, sin inyectar casos de uso.
- ❌ Sin lógica de negocio ni mapeo de datos en componentes.

### 7. Configuración (config)

```typescript
// config/app.config.ts
import { ApplicationConfig } from '@angular/core';
import { provideRouter, withComponentInputBinding } from '@angular/router';
import { provideHttpClient, withFetch } from '@angular/common/http';
import { routes } from './app.routes';
import { AlbumGateway } from '../domain/models/album/gateway/album-gateway';
import { AlbumApiAdapter } from '../infraestructure/driven-adapter/album-api/album-api.adapter';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes, withComponentInputBinding()),
    provideHttpClient(withFetch()),
    { provide: AlbumGateway, useClass: AlbumApiAdapter }, // 🔑 abstracción → implementación
  ],
};
```

Cambiar de fuente de datos = cambiar SOLO la línea `useClass`.

## 🔁 FLUJO PARA AÑADIR UNA ENTIDAD NUEVA

Sigue este orden y no saltes pasos:

1. `domain/models/<entity>/<entity>.ts`: modelo.
2. `domain/models/<entity>/gateway/<entity>-gateway.ts`: contrato abstracto.
3. `domain/usecase/<action>-<entity>.use-case.ts`: caso de uso + test con gateway mock.
4. `infraestructure/helpers/mappers/<entity>.mapper.ts`: mapper.
5. `infraestructure/driven-adapter/<entity>-<source>/<entity>-<source>.adapter.ts`: adaptador + test.
6. `config/app.config.ts`: añadir `{ provide: <Entity>Gateway, useClass: <Entity><Source>Adapter }`.
7. `UI/pages/<page>/`: página que inyecta el caso de uso + ruta lazy en `app.routes.ts`.

## 🏷️ CONVENCIONES DE NOMBRADO

| Artefacto | Archivo | Clase / símbolo |
|-----------|---------|-----------------|
| Modelo | `album.ts` | `Album` |
| Gateway | `album-gateway.ts` | `AlbumGateway` |
| Caso de uso | `get-album.use-case.ts` | `GetAlbumUseCase` |
| Adaptador | `album-api.adapter.ts` | `AlbumApiAdapter` |
| Mapper | `album.mapper.ts` | `AlbumMapper` |
| Página / componente | `album.component.ts` | `AlbumComponent` |

## 🧪 TESTING POR CAPA

| Capa | Qué se prueba | Cómo |
|------|---------------|------|
| domain | Casos de uso y reglas del modelo | Gateway mock vía `TestBed` provider `{ provide: XGateway, useValue: mock }` |
| infraestructure | Adaptadores y mappers | `provideHttpClientTesting()` + `HttpTestingController`; mappers con datos crudos |
| UI | Renderizado e interacción | Caso de uso mock; verificar DOM y signals |

## ❌ ANTI-PATRONES (RECHAZAR SIEMPRE)

| Anti-patrón | Corrección |
|-------------|------------|
| Componente que inyecta un adaptador | Inyectar el caso de uso |
| `HttpClient` (o cualquier tecnología) en `domain` | Usar el gateway abstracto |
| `interface` como gateway inyectable | `abstract class` |
| Lógica de negocio o mapeo en componentes | Mover a caso de uso o mapper |
| `subscribe()` manual sin liberar | `toSignal()`, `async` pipe o `takeUntilDestroyed()` |
| `*ngIf` / `*ngFor` / `NgModule` en código nuevo | `@if` / `@for` / standalone |
| `any` en firmas públicas | Tipos del dominio o `unknown` + mapper |
| Caso de uso "dios" con muchas responsabilidades | Dividir por responsabilidad |

## ✅ CHECKLIST ANTES DE ENTREGAR CÓDIGO

- [ ] `domain` no importa nada de `infraestructure`, `UI` ni `@angular/common/http`.
- [ ] Cada gateway nuevo está registrado en `app.config.ts`.
- [ ] Componentes standalone, `OnPush`, signals y control de flujo nativo.
- [ ] Sin `any`, sin suscripciones huérfanas, sin dependencias npm no solicitadas.
- [ ] Tests creados para caso de uso, adaptador y mapper nuevos.
- [ ] Código en inglés, textos de UI en español.
