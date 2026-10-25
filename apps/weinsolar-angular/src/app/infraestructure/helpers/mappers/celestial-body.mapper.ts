import {
  CelestialBody,
  CelestialBodyId,
  LightingProfile,
  SkyOpticalKeyframe,
  SkyOpticalProfile,
  TerrainTheme,
} from '../../../domain/models/celestial-body/celestial-body';

export const CelestialBodyMapper = {
  fromRaw(raw: unknown): CelestialBody {
    const obj = raw as Record<string, unknown>;
    const rawTerrain = obj['terrainTheme'] as Record<string, unknown>;
    const rawSky = obj['skyOpticalProfile'] as Record<string, unknown>;
    const rawLighting = obj['lightingProfile'] as Record<string, unknown> | undefined;

    if (!rawLighting || typeof rawLighting !== 'object') {
      throw new Error(
        `Domain error: missing required lightingProfile for CelestialBody "${String(obj['id'] ?? 'unknown')}".`,
      );
    }

    const rawKeyframes = (rawSky['keyframes'] as unknown[]) ?? [];

    const terrainTheme: TerrainTheme = {
      kind: String(rawTerrain['kind']) as TerrainTheme['kind'],
      primarySurfaceHex: String(rawTerrain['primarySurfaceHex'] ?? ''),
      secondarySurfaceHex: String(rawTerrain['secondarySurfaceHex'] ?? ''),
      featureColorHex: String(rawTerrain['featureColorHex'] ?? ''),
      accentFeatureColorHex: String(rawTerrain['accentFeatureColorHex'] ?? ''),
      landingPadColorHex: String(rawTerrain['landingPadColorHex'] ?? ''),
      landingPadTrimHex: String(rawTerrain['landingPadTrimHex'] ?? ''),
    };

    const keyframes: SkyOpticalKeyframe[] = rawKeyframes.map((item) => {
      const kf = item as Record<string, unknown>;
      return {
        elevationDeg: Number(kf['elevationDeg']),
        zenithColorHex: String(kf['zenithColorHex'] ?? ''),
        horizonColorHex: String(kf['horizonColorHex'] ?? ''),
        sunHaloColorHex: String(kf['sunHaloColorHex'] ?? ''),
        sunDiscColorHex: String(kf['sunDiscColorHex'] ?? ''),
        ambientLightIntensity: Number(kf['ambientLightIntensity']),
      };
    });

    const skyOpticalProfile: SkyOpticalProfile = {
      scientificReference: String(rawSky['scientificReference'] ?? ''),
      descriptionEs: String(rawSky['descriptionEs'] ?? ''),
      shadowHardness: Number(rawSky['shadowHardness']),
      hasAtmosphere: Boolean(rawSky['hasAtmosphere']),
      keyframes,
    };

    const lightingProfile: LightingProfile = {
      sunAzimuthDeg: Number(rawLighting['sunAzimuthDeg']),
      sunColorDayHex: String(rawLighting['sunColorDayHex'] ?? ''),
      sunColorSunsetHex: String(rawLighting['sunColorSunsetHex'] ?? ''),
      ambientDayIntensity: Number(rawLighting['ambientDayIntensity']),
      twilightFadeDeg: Number(rawLighting['twilightFadeDeg']),
      shadowSoftness: Number(rawLighting['shadowSoftness']),
      scientificReference: String(rawLighting['scientificReference'] ?? ''),
    };

    return {
      id: String(obj['id']) as CelestialBodyId,
      nameEs: String(obj['nameEs'] ?? ''),
      gravity: Number(obj['gravity']),
      atmosphericDensity: Number(obj['atmosphericDensity']),
      timeScale: Number(obj['timeScale']),
      initialAltitude: Number(obj['initialAltitude']),
      ceilingAltitude: Number(obj['ceilingAltitude']),
      initialVelocity: Number(obj['initialVelocity']),
      initialFuel: Number(obj['initialFuel']),
      terrainTheme,
      skyOpticalProfile,
      lightingProfile,
    };
  },
};
