import { TestBed } from '@angular/core/testing';
import { firstValueFrom, of } from 'rxjs';
import { CelestialBody } from '../models/celestial-body/celestial-body';
import { CelestialBodyGateway } from '../models/celestial-body/gateway/celestial-body-gateway';
import { GetCelestialBodiesUseCase } from './get-celestial-bodies.use-case';

const MOCK_BODIES: CelestialBody[] = [
  {
    id: 'earth',
    nameEs: 'Tierra',
    gravity: 9.81,
    atmosphericDensity: 1.225,
    timeScale: 2,
    initialAltitude: 500,
    ceilingAltitude: 750,
    initialVelocity: -25.0,
    initialFuel: 100.0,
    terrainTheme: {
      kind: 'earth-meadow-rocks',
      primarySurfaceHex: '#3B5E34',
      secondarySurfaceHex: '#2E4A28',
      featureColorHex: '#5C6468',
      accentFeatureColorHex: '#4A7A3D',
      landingPadColorHex: '#7A8288',
      landingPadTrimHex: '#C7A336',
    },
    skyOpticalProfile: {
      scientificReference: 'NASA Earth Observatory — Dispersión molecular de Rayleigh',
      descriptionEs: 'Dispersión molecular de Rayleigh con transición azul a naranja/rojo.',
      shadowHardness: 0.65,
      hasAtmosphere: true,
      keyframes: [
        {
          elevationDeg: 65,
          zenithColorHex: '#1E5799',
          horizonColorHex: '#7DB9E8',
          sunHaloColorHex: '#FFFDF4',
          sunDiscColorHex: '#FFFDF4',
          ambientLightIntensity: 0.75,
        },
      ],
    },
  },
  {
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
      scientificReference: 'NASA Mars Science Laboratory Curiosity — PIA19400 (Gale Crater sunset)',
      descriptionEs: 'Polvo fino marciano en suspensión con halo solar azul frío al atardecer.',
      shadowHardness: 0.55,
      hasAtmosphere: true,
      keyframes: [
        {
          elevationDeg: 65,
          zenithColorHex: '#C67D50',
          horizonColorHex: '#E2A878',
          sunHaloColorHex: '#F3D3B0',
          sunDiscColorHex: '#FFF5E8',
          ambientLightIntensity: 0.6,
        },
      ],
    },
  },
  {
    id: 'moon',
    nameEs: 'Luna',
    gravity: 1.62,
    atmosphericDensity: 0.0,
    timeScale: 4,
    initialAltitude: 500,
    ceilingAltitude: 750,
    initialVelocity: -15.0,
    initialFuel: 100.0,
    terrainTheme: {
      kind: 'moon-craters',
      primarySurfaceHex: '#73767A',
      secondarySurfaceHex: '#525558',
      featureColorHex: '#3B3D40',
      accentFeatureColorHex: '#92959A',
      landingPadColorHex: '#686A6E',
      landingPadTrimHex: '#C7A336',
    },
    skyOpticalProfile: {
      scientificReference: 'NASA Apollo 11–17 Surface Photography & LRO — Vacío exosférico',
      descriptionEs: 'Ausencia de atmósfera: cielo negro permanente y sombras negras de borde duro.',
      shadowHardness: 1.0,
      hasAtmosphere: false,
      keyframes: [
        {
          elevationDeg: 65,
          zenithColorHex: '#000000',
          horizonColorHex: '#000000',
          sunHaloColorHex: '#000000',
          sunDiscColorHex: '#FFFDF8',
          ambientLightIntensity: 0.0,
        },
      ],
    },
  },
  {
    id: 'titan',
    nameEs: 'Titán',
    gravity: 1.352,
    atmosphericDensity: 5.3,
    timeScale: 4,
    initialAltitude: 500,
    ceilingAltitude: 750,
    initialVelocity: -12.0,
    initialFuel: 100.0,
    terrainTheme: {
      kind: 'titan-icy-haze',
      primarySurfaceHex: '#6F4922',
      secondarySurfaceHex: '#523415',
      featureColorHex: '#84603C',
      accentFeatureColorHex: '#9A7248',
      landingPadColorHex: '#6A5B4C',
      landingPadTrimHex: '#C7A336',
    },
    skyOpticalProfile: {
      scientificReference: 'ESA/NASA/JPL-Caltech Huygens DISR Surface Images (14 enero 2005)',
      descriptionEs: 'Bruma densa ámbar/anaranjada por aerosoles de tolinas orgánicas.',
      shadowHardness: 0.15,
      hasAtmosphere: true,
      keyframes: [
        {
          elevationDeg: 65,
          zenithColorHex: '#B85D19',
          horizonColorHex: '#D9822B',
          sunHaloColorHex: '#E09A48',
          sunDiscColorHex: '#F0B265',
          ambientLightIntensity: 0.45,
        },
      ],
    },
  },
];

describe('GetCelestialBodiesUseCase (RN-01, FR-001, FR-002, FR-016, FR-024, SC-005)', () => {
  let useCase: GetCelestialBodiesUseCase;
  let gatewayMock: jasmine.SpyObj<CelestialBodyGateway>;

  beforeEach(() => {
    gatewayMock = jasmine.createSpyObj<CelestialBodyGateway>('CelestialBodyGateway', [
      'getAll',
      'getById',
    ]);
    gatewayMock.getAll.and.returnValue(of(MOCK_BODIES));
    gatewayMock.getById.and.callFake((id) => {
      const found = MOCK_BODIES.find((b) => b.id === id);
      if (!found) {
        throw new Error(`Unknown body ${id}`);
      }
      return of(found);
    });

    TestBed.configureTestingModule({
      providers: [
        GetCelestialBodiesUseCase,
        { provide: CelestialBodyGateway, useValue: gatewayMock },
      ],
    });

    useCase = TestBed.inject(GetCelestialBodiesUseCase);
  });

  it('should return exactly the 4 playable celestial bodies with Spanish names', async () => {
    const bodies = await firstValueFrom(useCase.getAll());
    expect(bodies.length).toBe(4);
    expect(bodies.map((b) => b.id)).toEqual(['earth', 'mars', 'moon', 'titan']);
    expect(bodies.map((b) => b.nameEs)).toEqual(['Tierra', 'Marte', 'Luna', 'Titán']);
  });

  it('should enforce astrophysical constants within < 1% margin (RN-01, SC-005)', async () => {
    const bodies = await firstValueFrom(useCase.getAll());
    const expected = {
      earth: { g: 9.81, rho: 1.225 },
      mars: { g: 3.71, rho: 0.02 },
      moon: { g: 1.62, rho: 0.0 },
      titan: { g: 1.352, rho: 5.3 },
    };

    for (const body of bodies) {
      const ref = expected[body.id];
      const gravityError = Math.abs(body.gravity - ref.g) / ref.g;
      expect(gravityError).toBeLessThan(0.01);
      if (ref.rho === 0) {
        expect(body.atmosphericDensity).toBe(0);
      } else {
        const densityError = Math.abs(body.atmosphericDensity - ref.rho) / ref.rho;
        expect(densityError).toBeLessThan(0.01);
      }
    }
  });

  it('should enforce ceilingAltitude === 1.5 * initialAltitude and non-empty scientificReference (FR-016, FR-024)', async () => {
    const bodies = await firstValueFrom(useCase.getAll());
    for (const body of bodies) {
      expect(body.ceilingAltitude).toBeCloseTo(1.5 * body.initialAltitude, 5);
      expect(body.skyOpticalProfile.scientificReference.trim().length).toBeGreaterThan(0);
    }
  });

  it('should retrieve a single world by id via getById', async () => {
    const mars = await firstValueFrom(useCase.getById('mars'));
    expect(mars.id).toBe('mars');
    expect(mars.nameEs).toBe('Marte');
    expect(mars.gravity).toBeCloseTo(3.71, 2);
  });
});
