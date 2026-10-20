import { TestBed } from '@angular/core/testing';
import { firstValueFrom } from 'rxjs';
import { CelestialBodyLocalAdapter } from '../../infraestructure/driven-adapter/celestial-body-local/celestial-body-local.adapter';
import { CelestialBody } from '../models/celestial-body/celestial-body';
import { ComputeSceneLightingUseCase } from './compute-scene-lighting.use-case';

function parseRgb(hex: string): [number, number, number] {
  const clean = hex.replace('#', '');
  return [
    parseInt(clean.substring(0, 2), 16),
    parseInt(clean.substring(2, 4), 16),
    parseInt(clean.substring(4, 6), 16),
  ];
}

function euclideanDistance(hexA: string, hexB: string): number {
  const [r1, g1, b1] = parseRgb(hexA);
  const [r2, g2, b2] = parseRgb(hexB);
  return Math.sqrt((r1 - r2) ** 2 + (g1 - g2) ** 2 + (b1 - b2) ** 2);
}

const WEINCODE_BRAND_PURPLES = ['#18084D', '#5236FF', '#A599FF'] as const;

describe('ComputeSceneLightingUseCase (T015 & T068 — RN-12, RN-13, RN-14, RN-15, FR-016, FR-018)', () => {
  let useCase: ComputeSceneLightingUseCase;
  let worldsById: Record<string, CelestialBody>;

  beforeEach(async () => {
    TestBed.configureTestingModule({
      providers: [ComputeSceneLightingUseCase, CelestialBodyLocalAdapter],
    });
    useCase = TestBed.inject(ComputeSceneLightingUseCase);
    const adapter = TestBed.inject(CelestialBodyLocalAdapter);
    const list = await firstValueFrom(adapter.getAll());
    worldsById = {
      earth: list.find((w) => w.id === 'earth')!,
      mars: list.find((w) => w.id === 'mars')!,
      moon: list.find((w) => w.id === 'moon')!,
      titan: list.find((w) => w.id === 'titan')!,
    };
  });

  it('should return a normalized sunDirection with y = sin(e) (tolerance 1e-9) for e in {65, 45, 10, 0, -10}', () => {
    const earth = worldsById['earth'];
    for (const elev of [65, 45, 10, 0, -10]) {
      const state = useCase.execute(earth, elev);
      const { x, y, z } = state.sunDirection;
      const norm = Math.sqrt(x * x + y * y + z * z);
      const expectedY = Math.sin((elev * Math.PI) / 180);

      expect(Math.abs(norm - 1.0)).withContext(`norm at ${elev}°`).toBeLessThanOrEqual(1e-9);
      expect(Math.abs(y - expectedY)).withContext(`y at ${elev}°`).toBeLessThanOrEqual(1e-9);
    }
  });

  it('should set castsShadows === (e > 0) and expectedShadowLengthRatio = 1/tan(e) monotonically increasing from 89° to 1° (RN-12)', () => {
    const earth = worldsById['earth'];

    const s45 = useCase.execute(earth, 45);
    expect(s45.castsShadows).toBe(true);
    expect(Math.abs(s45.expectedShadowLengthRatio! - 1.0)).toBeLessThanOrEqual(1e-6);

    const s10 = useCase.execute(earth, 10);
    expect(s10.castsShadows).toBe(true);
    expect(Math.abs(s10.expectedShadowLengthRatio! - 1 / Math.tan((10 * Math.PI) / 180))).toBeLessThanOrEqual(1e-6);

    let prevRatio = 0;
    for (let e = 89; e >= 1; e--) {
      const ratio = useCase.execute(earth, e).expectedShadowLengthRatio!;
      expect(ratio).withContext(`monotonic at ${e}°`).toBeGreaterThan(prevRatio);
      prevRatio = ratio;
    }

    for (const nonPos of [0, -5, -10]) {
      const s = useCase.execute(earth, nonPos);
      expect(s.castsShadows).withContext(`castsShadows at ${nonPos}°`).toBe(false);
      expect(s.expectedShadowLengthRatio)
        .withContext(`expectedShadowLengthRatio at ${nonPos}°`)
        .toBeNull();
    }
  });

  it('should clamp solarElevationDeg to [-10, 90] and be strictly deterministic', () => {
    const mars = worldsById['mars'];

    const low = useCase.execute(mars, -45);
    expect(low.solarElevationDeg).toBe(-10);

    const high = useCase.execute(mars, 130);
    expect(high.solarElevationDeg).toBe(90);

    const first = useCase.execute(mars, 18.5);
    const second = useCase.execute(mars, 18.5);
    expect(first).toEqual(second);
  });

  it('should copy shadowSoftness from LightingProfile for each world (RN-15)', () => {
    for (const world of Object.values(worldsById)) {
      const state = useCase.execute(world, 65);
      expect(state.shadowSoftness).toBe(world.lightingProfile.shadowSoftness);
    }
  });

  it('should produce Mars cool blue-tinted sunset light at 2° and Earth warm orange sunset light at 2° (FR-016)', () => {
    const marsState = useCase.execute(worldsById['mars'], 2);
    expect(euclideanDistance(marsState.sunColorHex, '#6C93B8')).toBeLessThan(30);

    const earthState = useCase.execute(worldsById['earth'], 2);
    const [r, , b] = parseRgb(earthState.sunColorHex);
    expect(r).toBeGreaterThan(b + 100);
  });

  it('should enforce Moon vacuum lighting (ambientIntensity == 0 and abrupt sunIntensity cutoff at 0°) and Titan diffuse twilight down to -10°', () => {
    const moon = worldsById['moon'];
    for (const elev of [-10, -1, -0.1, 0, 0.1, 10, 45, 90]) {
      const state = useCase.execute(moon, elev);
      expect(state.ambientIntensity).withContext(`moon ambient at ${elev}°`).toBe(0);
    }
    expect(useCase.execute(moon, 0.1).sunIntensity).toBeGreaterThan(0);
    expect(useCase.execute(moon, -0.1).sunIntensity).toBe(0);

    const titan = worldsById['titan'];
    expect(useCase.execute(titan, 45).shadowSoftness).toBe(0.9);
    let prevIntensity = useCase.execute(titan, 20).sunIntensity;
    for (let e = 19; e >= -10; e--) {
      const curr = useCase.execute(titan, e).sunIntensity;
      expect(curr).withContext(`Titan sunIntensity at ${e}°`).toBeLessThanOrEqual(prevIntensity);
      prevIntensity = curr;
    }
    expect(useCase.execute(titan, -5).sunIntensity).toBeGreaterThan(0);
  });

  it('should vary sunIntensity and color channels smoothly (delta <= 0.08 per 0.5° step) on Earth, Mars, and Titan (FR-018)', () => {
    for (const id of ['earth', 'mars', 'titan']) {
      const world = worldsById[id];
      for (let e = -10; e <= 89.5; e += 0.5) {
        const a = useCase.execute(world, e);
        const b = useCase.execute(world, e + 0.5);

        expect(Math.abs(a.sunIntensity - b.sunIntensity))
          .withContext(`${id} sunIntensity delta at ${e}°`)
          .toBeLessThanOrEqual(0.08);

        const [sr1, sg1, sb1] = parseRgb(a.sunColorHex);
        const [sr2, sg2, sb2] = parseRgb(b.sunColorHex);
        expect(Math.abs(sr1 - sr2) / 255).toBeLessThanOrEqual(0.08);
        expect(Math.abs(sg1 - sg2) / 255).toBeLessThanOrEqual(0.08);
        expect(Math.abs(sb1 - sb2) / 255).toBeLessThanOrEqual(0.08);

        const [ar1, ag1, ab1] = parseRgb(a.ambientSkyColorHex);
        const [ar2, ag2, ab2] = parseRgb(b.ambientSkyColorHex);
        expect(Math.abs(ar1 - ar2) / 255).toBeLessThanOrEqual(0.08);
        expect(Math.abs(ag1 - ag2) / 255).toBeLessThanOrEqual(0.08);
        expect(Math.abs(ab1 - ab2) / 255).toBeLessThanOrEqual(0.08);
      }
    }
  });

  it('should satisfy RN-13 chromatic separation across every 1° step from -10° to 90° for all worlds', () => {
    for (const world of Object.values(worldsById)) {
      for (let e = -10; e <= 90; e += 1) {
        const state = useCase.execute(world, e);
        for (const color of [state.sunColorHex, state.ambientSkyColorHex]) {
          for (const purple of WEINCODE_BRAND_PURPLES) {
            expect(euclideanDistance(color, purple))
              .withContext(`${world.id} at ${e}° (${color} vs ${purple})`)
              .toBeGreaterThanOrEqual(48);
          }
          expect(euclideanDistance(color, '#FFFFFF'))
            .withContext(`${world.id} at ${e}° (${color} vs #FFFFFF)`)
            .toBeGreaterThanOrEqual(16);
        }
      }
    }
  });
});
