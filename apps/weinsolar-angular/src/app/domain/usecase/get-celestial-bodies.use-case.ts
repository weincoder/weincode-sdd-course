import { Injectable, inject } from '@angular/core';
import { Observable, map } from 'rxjs';
import { CelestialBody, CelestialBodyId } from '../models/celestial-body/celestial-body';
import { CelestialBodyGateway } from '../models/celestial-body/gateway/celestial-body-gateway';

const CANONICAL_CONSTANTS: Record<CelestialBodyId, { gravity: number; density: number }> = {
  earth: { gravity: 9.81, density: 1.225 },
  mars: { gravity: 3.71, density: 0.02 },
  moon: { gravity: 1.62, density: 0.0 },
  titan: { gravity: 1.352, density: 5.3 },
};

@Injectable({ providedIn: 'root' })
export class GetCelestialBodiesUseCase {
  private readonly celestialBodyGateway = inject(CelestialBodyGateway);

  getAll(): Observable<CelestialBody[]> {
    return this.celestialBodyGateway.getAll().pipe(
      map((bodies) => {
        for (const body of bodies) {
          this.validateInvariants(body);
        }
        return bodies;
      }),
    );
  }

  getById(id: CelestialBodyId): Observable<CelestialBody> {
    return this.celestialBodyGateway.getById(id).pipe(
      map((body) => {
        this.validateInvariants(body);
        return body;
      }),
    );
  }

  private validateInvariants(body: CelestialBody): void {
    const reference = CANONICAL_CONSTANTS[body.id];
    const gravityDeviation = Math.abs(body.gravity - reference.gravity) / reference.gravity;
    if (gravityDeviation > 0.01) {
      throw new Error(`Invalid gravity for ${body.id}: ${body.gravity}`);
    }
    if (reference.density === 0 && body.atmosphericDensity !== 0) {
      throw new Error(`Moon atmospheric density must be 0, got ${body.atmosphericDensity}`);
    }
    if (reference.density > 0) {
      const densityDeviation =
        Math.abs(body.atmosphericDensity - reference.density) / reference.density;
      if (densityDeviation > 0.01) {
        throw new Error(`Invalid atmospheric density for ${body.id}: ${body.atmosphericDensity}`);
      }
    }
    if (Math.abs(body.ceilingAltitude - 1.5 * body.initialAltitude) > 0.001) {
      throw new Error(`Invalid ceiling altitude for ${body.id}`);
    }
    if (!body.skyOpticalProfile.scientificReference.trim()) {
      throw new Error(`Missing scientificReference for ${body.id}`);
    }
  }
}
