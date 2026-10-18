import { TestBed } from '@angular/core/testing';
import { firstValueFrom } from 'rxjs';
import { CelestialBodyLocalAdapter } from './celestial-body-local.adapter';

describe('CelestialBodyLocalAdapter (RN-01, FR-001, FR-002, FR-016, FR-024, SC-005)', () => {
  let adapter: CelestialBodyLocalAdapter;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [CelestialBodyLocalAdapter],
    });
    adapter = TestBed.inject(CelestialBodyLocalAdapter);
  });

  it('should provide all 4 worlds offline with exact Spanish names and astrophysical constants', async () => {
    const worlds = await firstValueFrom(adapter.getAll());
    expect(worlds.length).toBe(4);
    expect(worlds.map((w) => w.id)).toEqual(['earth', 'mars', 'moon', 'titan']);
    expect(worlds.map((w) => w.nameEs)).toEqual(['Tierra', 'Marte', 'Luna', 'Titán']);

    const [earth, mars, moon, titan] = worlds;
    expect(earth.gravity).toBeCloseTo(9.81, 2);
    expect(earth.atmosphericDensity).toBeCloseTo(1.225, 3);

    expect(mars.gravity).toBeCloseTo(3.71, 2);
    expect(mars.atmosphericDensity).toBeCloseTo(0.02, 3);

    expect(moon.gravity).toBeCloseTo(1.62, 2);
    expect(moon.atmosphericDensity).toBe(0.0);

    expect(titan.gravity).toBeCloseTo(1.352, 3);
    expect(titan.atmosphericDensity).toBeCloseTo(5.3, 2);
  });

  it('should configure ceilingAltitude === 1.5 * initialAltitude and non-empty scientificReference for all worlds', async () => {
    const worlds = await firstValueFrom(adapter.getAll());
    for (const world of worlds) {
      expect(world.initialAltitude).toBe(500);
      expect(world.ceilingAltitude).toBe(750);
      expect(world.ceilingAltitude).toBe(1.5 * world.initialAltitude);
      expect(world.skyOpticalProfile.scientificReference.length).toBeGreaterThan(10);
    }
  });

  it('should return each world via getById without network calls', async () => {
    const titan = await firstValueFrom(adapter.getById('titan'));
    expect(titan.nameEs).toBe('Titán');
    expect(titan.timeScale).toBe(4);
  });
});
