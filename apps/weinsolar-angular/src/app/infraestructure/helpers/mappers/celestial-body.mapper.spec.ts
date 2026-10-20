import { TestBed } from '@angular/core/testing';
import { firstValueFrom } from 'rxjs';
import { CelestialBodyLocalAdapter } from '../../driven-adapter/celestial-body-local/celestial-body-local.adapter';
import { CelestialBodyMapper } from './celestial-body.mapper';

function parseRgb(hex: string): [number, number, number] {
  const clean = hex.replace('#', '');
  return [
    parseInt(clean.substring(0, 2), 16),
    parseInt(clean.substring(2, 4), 16),
    parseInt(clean.substring(4, 6), 16),
  ];
}

function rgbDistance(hexA: string, hexB: string): number {
  const [r1, g1, b1] = parseRgb(hexA);
  const [r2, g2, b2] = parseRgb(hexB);
  const dr = r1 - r2;
  const dg = g1 - g2;
  const db = b1 - b2;
  return Math.sqrt(dr * dr + dg * dg + db * db);
}

describe('CelestialBodyMapper (T017 — lightingProfile & RN-13)', () => {
  const validRaw: Record<string, unknown> = {
    id: 'mars',
    nameEs: 'Marte',
    gravity: 3.71,
    atmosphericDensity: 0.02,
    timeScale: 3,
    initialAltitude: 500,
    ceilingAltitude: 750,
    initialVelocity: -20.0,
    initialFuel: 100.0,
    terrainTheme: {
      kind: 'mars-regolith-rocks',
      primarySurfaceHex: '#8C442A',
      secondarySurfaceHex: '#6B311D',
      featureColorHex: '#4F2415',
      accentFeatureColorHex: '#B8623E',
      landingPadColorHex: '#6D6764',
      landingPadTrimHex: '#C7A336',
    },
    skyOpticalProfile: {
      scientificReference: 'NASA Mars Science Laboratory Curiosity — PIA19400',
      descriptionEs: 'Dispersión Mie en polvo fino marciano con halo azul frío.',
      shadowHardness: 0.55,
      hasAtmosphere: true,
      keyframes: [
        {
          elevationDeg: 10,
          zenithColorHex: '#6E473B',
          horizonColorHex: '#8C5843',
          sunHaloColorHex: '#6C93B8',
          sunDiscColorHex: '#BFD9F2',
          ambientLightIntensity: 0.35,
        },
      ],
    },
    lightingProfile: {
      sunAzimuthDeg: 250,
      sunColorDayHex: '#FFE9D2',
      sunColorSunsetHex: '#6C93B8',
      ambientDayIntensity: 0.4,
      twilightFadeDeg: 8,
      shadowSoftness: 0.45,
      scientificReference: 'NASA Mars Science Laboratory Curiosity — PIA19400',
    },
  };

  it('should map raw unknown object into a strongly typed CelestialBody including lightingProfile', () => {
    const mapped = CelestialBodyMapper.fromRaw(validRaw);
    expect(mapped.id).toBe('mars');
    expect(mapped.nameEs).toBe('Marte');
    expect(mapped.gravity).toBe(3.71);
    expect(mapped.atmosphericDensity).toBe(0.02);
    expect(mapped.ceilingAltitude).toBe(750);
    expect(mapped.skyOpticalProfile.keyframes.length).toBe(1);
    expect(mapped.skyOpticalProfile.keyframes[0].sunHaloColorHex).toBe('#6C93B8');
    expect(mapped.lightingProfile).toEqual({
      sunAzimuthDeg: 250,
      sunColorDayHex: '#FFE9D2',
      sunColorSunsetHex: '#6C93B8',
      ambientDayIntensity: 0.4,
      twilightFadeDeg: 8,
      shadowSoftness: 0.45,
      scientificReference: 'NASA Mars Science Laboratory Curiosity — PIA19400',
    });
  });

  it('should throw a domain error when lightingProfile is missing (no silent defaults)', () => {
    const withoutLighting = { ...validRaw };
    delete withoutLighting['lightingProfile'];
    expect(() => CelestialBodyMapper.fromRaw(withoutLighting)).toThrowError(/lightingProfile/i);
  });

  it('should enforce RN-13 RGB distances on all colors of LightingProfile, SkyOpticalProfile, and TerrainTheme across all 4 worlds', async () => {
    TestBed.configureTestingModule({ providers: [CelestialBodyLocalAdapter] });
    const adapter = TestBed.inject(CelestialBodyLocalAdapter);
    const worlds = await firstValueFrom(adapter.getAll());

    const weincodeVioletPalette = ['#18084D', '#5236FF', '#A599FF'];
    const weincodeAll = new Set(['#18084D', '#5236FF', '#A599FF', '#FFFFFF']);

    for (const world of worlds) {
      const colorsToCheck: { label: string; hex: string }[] = [
        { label: `${world.id}.lighting.sunColorDayHex`, hex: world.lightingProfile.sunColorDayHex },
        {
          label: `${world.id}.lighting.sunColorSunsetHex`,
          hex: world.lightingProfile.sunColorSunsetHex,
        },
        { label: `${world.id}.terrain.primarySurfaceHex`, hex: world.terrainTheme.primarySurfaceHex },
        {
          label: `${world.id}.terrain.secondarySurfaceHex`,
          hex: world.terrainTheme.secondarySurfaceHex,
        },
        { label: `${world.id}.terrain.featureColorHex`, hex: world.terrainTheme.featureColorHex },
        {
          label: `${world.id}.terrain.accentFeatureColorHex`,
          hex: world.terrainTheme.accentFeatureColorHex,
        },
        {
          label: `${world.id}.terrain.landingPadColorHex`,
          hex: world.terrainTheme.landingPadColorHex,
        },
        {
          label: `${world.id}.terrain.landingPadTrimHex`,
          hex: world.terrainTheme.landingPadTrimHex,
        },
      ];

      for (const kf of world.skyOpticalProfile.keyframes) {
        colorsToCheck.push(
          { label: `${world.id}.sky@${kf.elevationDeg}.zenith`, hex: kf.zenithColorHex },
          { label: `${world.id}.sky@${kf.elevationDeg}.horizon`, hex: kf.horizonColorHex },
          { label: `${world.id}.sky@${kf.elevationDeg}.halo`, hex: kf.sunHaloColorHex },
          { label: `${world.id}.sky@${kf.elevationDeg}.disc`, hex: kf.sunDiscColorHex },
        );
      }

      for (const item of colorsToCheck) {
        const upper = item.hex.toUpperCase();
        expect(weincodeAll.has(upper)).withContext(`${item.label} (${upper})`).toBe(false);
        for (const forbidden of weincodeVioletPalette) {
          expect(rgbDistance(upper, forbidden))
            .withContext(`${item.label} (${upper}) distance to ${forbidden}`)
            .toBeGreaterThanOrEqual(48);
        }
        expect(rgbDistance(upper, '#FFFFFF'))
          .withContext(`${item.label} (${upper}) distance to #FFFFFF`)
          .toBeGreaterThanOrEqual(16);
      }
    }
  });
});
