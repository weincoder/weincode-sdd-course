import { Observable } from 'rxjs';
import { CelestialBody, CelestialBodyId } from '../celestial-body';

export abstract class CelestialBodyGateway {
  abstract getAll(): Observable<CelestialBody[]>;
  abstract getById(id: CelestialBodyId): Observable<CelestialBody>;
}
