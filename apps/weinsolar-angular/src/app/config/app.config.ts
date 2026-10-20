import { ApplicationConfig, provideAppInitializer } from '@angular/core';
import { provideRouter, withComponentInputBinding } from '@angular/router';
import { routes } from './app.routes';
import { CelestialBodyGateway } from '../domain/models/celestial-body/gateway/celestial-body-gateway';
import { CelestialBodyLocalAdapter } from '../infraestructure/driven-adapter/celestial-body-local/celestial-body-local.adapter';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes, withComponentInputBinding()),
    provideAppInitializer(async () => {
      const [{ registerNgtCatalogue }, { preloadLanderGlb }] = await Promise.all([
        import('../UI/ds/organisms/planetary-scene-3d/ngt-extend'),
        import('../UI/ds/organisms/planetary-scene-3d/lander-model.component'),
      ]);
      registerNgtCatalogue();
      preloadLanderGlb();
    }),
    { provide: CelestialBodyGateway, useClass: CelestialBodyLocalAdapter },
  ],
};
