import { TestBed } from '@angular/core/testing';
import { firstValueFrom } from 'rxjs';
import { CelestialBodyLocalAdapter } from '../../infraestructure/driven-adapter/celestial-body-local/celestial-body-local.adapter';
import { CelestialBody } from '../models/celestial-body/celestial-body';
import { VisualQuality } from '../models/scene/visual-quality';
import { GenerateTerrainLayoutUseCase } from './generate-terrain-layout.use-case';

describe('GenerateTerrainLayoutUseCase (T037 — RN-10, RN-15, US1)', () => {
  let useCase: GenerateTerrainLayoutUseCase;
  let worldsById: Record<string, CelestialBody>;

  beforeEach(async () => {
    TestBed.configureTestingModule({
      providers: [GenerateTerrainLayoutUseCase, CelestialBodyLocalAdapter],
    });
    useCase = TestBed.inject(GenerateTerrainLayoutUseCase);
    const adapter = TestBed.inject(CelestialBodyLocalAdapter);
    const list = await firstValueFrom(adapter.getAll());
    worldsById = {
      earth: list.find((w) => w.id === 'earth')!,
      mars: list.find((w) => w.id === 'mars')!,
      moon: list.find((w) => w.id === 'moon')!,
      titan: list.find((w) => w.id === 'titan')!,
    };
  });

  it('should generate deterministic layouts with resolution 192 (high) and 64 (basic) and heights.length === resolution^2', () => {
    for (const world of Object.values(worldsById)) {
      for (const quality of ['high', 'basic'] as VisualQuality[]) {
        const expectedRes = quality === 'high' ? 192 : 64;
        const first = useCase.execute(world, quality);
        const second = useCase.execute(world, quality);

        expect(first).toEqual(second);
        expect(first.sizeMeters).toBe(600);
        expect(first.padRadiusMeters).toBe(6.0);
        expect(first.resolution).toBe(expectedRes);
        expect(first.heights.length).toBe(expectedRes * expectedRes);
      }
    }
  });

  it('should enforce RN-10: exact height === 0 on vertices within padRadiusMeters (6.0 m) and no TerrainFeature within padRadius + 2 m (8.0 m)', () => {
    for (const world of Object.values(worldsById)) {
      for (const quality of ['high', 'basic'] as VisualQuality[]) {
        const layout = useCase.execute(world, quality);
        const res = layout.resolution;
        const half = layout.sizeMeters / 2;

        for (let row = 0; row < res; row++) {
          const z = -half + (row / (res - 1)) * layout.sizeMeters;
          for (let col = 0; col < res; col++) {
            const x = -half + (col / (res - 1)) * layout.sizeMeters;
            const dist = Math.sqrt(x * x + z * z);
            if (dist <= layout.padRadiusMeters) {
              expect(layout.heights[row * res + col])
                .withContext(`${world.id} (${quality}) vertex (${x.toFixed(2)}, ${z.toFixed(2)})`)
                .toBe(0);
            }
          }
        }

        for (const feat of layout.features) {
          const dist = Math.sqrt(feat.x * feat.x + feat.z * feat.z);
          expect(dist)
            .withContext(`${world.id} (${quality}) feature at (${feat.x}, ${feat.z})`)
            .toBeGreaterThanOrEqual(layout.padRadiusMeters + 2.0);
        }
      }
    }
  });

  it('should produce world-characteristic terrain features and keep basic feature count within ~40% of high (+-1) (RN-15)', () => {
    const earthHigh = useCase.execute(worldsById['earth'], 'high');
    expect(earthHigh.features.some((f) => f.kind === 'rock')).toBe(true);
    expect(earthHigh.features.some((f) => f.kind === 'vegetation')).toBe(true);

    const marsHigh = useCase.execute(worldsById['mars'], 'high');
    expect(marsHigh.features.some((f) => f.kind === 'rock')).toBe(true);
    expect(marsHigh.features.some((f) => f.kind === 'dune')).toBe(true);

    const moonHigh = useCase.execute(worldsById['moon'], 'high');
    expect(moonHigh.features.some((f) => f.kind === 'crater')).toBe(true);

    const titanHigh = useCase.execute(worldsById['titan'], 'high');
    expect(titanHigh.features.some((f) => f.kind === 'iceRidge')).toBe(true);

    for (const world of Object.values(worldsById)) {
      const highCount = useCase.execute(world, 'high').features.length;
      const basicCount = useCase.execute(world, 'basic').features.length;
      const expectedBasic = Math.round(highCount * 0.4);
      expect(Math.abs(basicCount - expectedBasic))
        .withContext(`${world.id} basic=${basicCount} vs 40% of high=${highCount}`)
        .toBeLessThanOrEqual(1);
    }
  });
});
