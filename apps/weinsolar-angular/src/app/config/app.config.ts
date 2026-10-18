import { ApplicationConfig } from '@angular/core';
import { provideRouter, withComponentInputBinding } from '@angular/router';
import { routes } from './app.routes';
import { CelestialBodyGateway } from '../domain/models/celestial-body/gateway/celestial-body-gateway';
import { CelestialBodyLocalAdapter } from '../infraestructure/driven-adapter/celestial-body-local/celestial-body-local.adapter';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes, withComponentInputBinding()),
    { provide: CelestialBodyGateway, useClass: CelestialBodyLocalAdapter },
  ],
};
