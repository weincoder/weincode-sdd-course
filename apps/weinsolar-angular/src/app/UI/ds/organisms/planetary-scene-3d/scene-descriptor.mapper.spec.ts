import { CelestialBody } from '../../../../domain/models/celestial-body/celestial-body';
import { SceneLightingState } from '../../../../domain/models/scene/scene-lighting-state';
import { TerrainLayout } from '../../../../domain/models/scene/terrain-layout';
import { LanderState } from '../../../../domain/models/simulation/lander-state';
import { SceneDescriptorMapper } from './scene-descriptor.mapper';

describe('SceneDescriptorMapper (T033 — R6, RN-09..RN-15)', () => {
  const mockWorld: CelestialBody = {
    id: 'earth',
    nameEs: 'Tierra',
    gravity: 9.81,
    atmosphericDensity: 1.225,
    timeScale: 2,
    initialAltitude: 500,
    ceilingAltitude: 750,
    initialVelocity: -25,
    initialFuel: 100,
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
      scientificReference: 'Ref',
      descriptionEs: 'Desc',
      shadowHardness: 0.65,
      hasAtmosphere: true,
      keyframes: [],
    },
    lightingProfile: {
      sunAzimuthDeg: 250,
      sunColorDayHex: '#FFF4E0',
      sunColorSunsetHex: '#FF7A2E',
      ambientDayIntensity: 0.45,
      twilightFadeDeg: 6,
      shadowSoftness: 0.35,
      scientificReference: 'Ref',
    },
  };

  const mockLighting: SceneLightingState = {
    solarElevationDeg: 65,
    sunDirection: { x: -0.397, y: 0.906, z: -0.144 },
    sunColorHex: '#FFF4E0',
    sunIntensity: 1.0,
    ambientSkyColorHex: '#1E5799',
    ambientGroundColorHex: '#3B5E34',
    ambientIntensity: 0.45,
    shadowSoftness: 0.35,
    castsShadows: true,
    expectedShadowLengthRatio: 0.466,
  };

  const mockTerrain: TerrainLayout = {
    sizeMeters: 600,
    resolution: 192,
    maxHeightMeters: 18,
    padRadiusMeters: 6,
    heights: [0, 0, 0, 0],
    features: [],
  };

  const baseLanderState: LanderState = {
    altitude: 120,
    verticalVelocity: -10,
    horizontalVelocity: 0,
    fuelPercentage: 80,
    isThrusterActive: true,
    status: 'descending',
    safeLandingThreshold: 2.0,
    isVelocitySafe: false,
    isNearCeiling: false,
  };

  it('should map QualitySettings table (R6) accurately for high and basic quality', () => {
    const highDesc = SceneDescriptorMapper.from({
      world: mockWorld,
      landerState: baseLanderState,
      lighting: mockLighting,
      terrain: mockTerrain,
      cameraMode: 'lateralFollow',
      cameraAzimuthDeg: 0,
      quality: 'high',
    });

    expect(highDesc.quality).toEqual({
      level: 'high',
      shadowMapSize: 2048,
      softShadows: true,
      terrainResolution: 192,
      featureDensityRatio: 1.0,
      atmosphericHazeEnabled: true,
      maxPixelRatio: 2.0,
    });

    const basicDesc = SceneDescriptorMapper.from({
      world: mockWorld,
      landerState: baseLanderState,
      lighting: mockLighting,
      terrain: { ...mockTerrain, resolution: 64 },
      cameraMode: 'orbit',
      cameraAzimuthDeg: 90,
      quality: 'basic',
    });

    expect(basicDesc.quality).toEqual({
      level: 'basic',
      shadowMapSize: 1024,
      softShadows: false,
      terrainResolution: 64,
      featureDensityRatio: 0.4,
      atmosphericHazeEnabled: false,
      maxPixelRatio: 1.25,
    });
  });

  it('should derive LanderVisualState and visible node per status without mutating inputs', () => {
    const frozenLander = Object.freeze({ ...baseLanderState });

    const descDescending = SceneDescriptorMapper.from({
      world: mockWorld,
      landerState: frozenLander,
      lighting: mockLighting,
      terrain: mockTerrain,
      cameraMode: 'lateralFollow',
      cameraAzimuthDeg: 0,
      quality: 'high',
    });
    expect(descDescending.lander.visibleNodeName).toBe('Lander_Intact');
    expect(descDescending.lander.showThrusterFlame).toBe(true);

    const descLanded = SceneDescriptorMapper.from({
      world: mockWorld,
      landerState: { ...baseLanderState, altitude: 0, status: 'landed', isThrusterActive: true },
      lighting: mockLighting,
      terrain: mockTerrain,
      cameraMode: 'orbit',
      cameraAzimuthDeg: 45,
      quality: 'high',
    });
    expect(descLanded.lander.visibleNodeName).toBe('Lander_Intact');
    expect(descLanded.lander.showThrusterFlame).toBe(false);

    const descCrashed = SceneDescriptorMapper.from({
      world: mockWorld,
      landerState: { ...baseLanderState, altitude: 0, status: 'crashed', isThrusterActive: false },
      lighting: mockLighting,
      terrain: mockTerrain,
      cameraMode: 'lateralFollow',
      cameraAzimuthDeg: 0,
      quality: 'high',
    });
    expect(descCrashed.lander.visibleNodeName).toBe('Lander_Destroyed');
    expect(descCrashed.lander.showThrusterFlame).toBe(false);

    const descLost = SceneDescriptorMapper.from({
      world: mockWorld,
      landerState: {
        ...baseLanderState,
        altitude: 760,
        status: 'lostSignal',
        isThrusterActive: true,
      },
      lighting: mockLighting,
      terrain: mockTerrain,
      cameraMode: 'lateralFollow',
      cameraAzimuthDeg: 0,
      quality: 'high',
    });
    expect(descLost.lander.visibleNodeName).toBe('Lander_Destroyed');
    expect(descLost.lander.showThrusterFlame).toBe(false);
  });
});
