import { CelestialBodyMapper } from './celestial-body.mapper';

describe('CelestialBodyMapper (T018)', () => {
  it('should map raw unknown object into a strongly typed CelestialBody', () => {
    const raw: unknown = {
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
    };

    const mapped = CelestialBodyMapper.fromRaw(raw);
    expect(mapped.id).toBe('mars');
    expect(mapped.nameEs).toBe('Marte');
    expect(mapped.gravity).toBe(3.71);
    expect(mapped.atmosphericDensity).toBe(0.02);
    expect(mapped.ceilingAltitude).toBe(750);
    expect(mapped.skyOpticalProfile.keyframes.length).toBe(1);
    expect(mapped.skyOpticalProfile.keyframes[0].sunHaloColorHex).toBe('#6C93B8');
  });
});
