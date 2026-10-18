export type CelestialBodyId = 'earth' | 'mars' | 'moon' | 'titan';

export interface TerrainTheme {
  readonly kind: 'earth-meadow-rocks' | 'mars-regolith-rocks' | 'moon-craters' | 'titan-icy-haze';
  readonly primarySurfaceHex: string;
  readonly secondarySurfaceHex: string;
  readonly featureColorHex: string;
  readonly accentFeatureColorHex: string;
  readonly landingPadColorHex: string;
  readonly landingPadTrimHex: string;
}

export interface SkyOpticalKeyframe {
  readonly elevationDeg: number;
  readonly zenithColorHex: string;
  readonly horizonColorHex: string;
  readonly sunHaloColorHex: string;
  readonly sunDiscColorHex: string;
  readonly ambientLightIntensity: number;
}

export interface SkyOpticalProfile {
  readonly scientificReference: string;
  readonly descriptionEs: string;
  readonly shadowHardness: number;
  readonly hasAtmosphere: boolean;
  readonly keyframes: readonly SkyOpticalKeyframe[];
}

export interface CelestialBody {
  readonly id: CelestialBodyId;
  readonly nameEs: string;
  readonly gravity: number;
  readonly atmosphericDensity: number;
  readonly timeScale: number;
  readonly initialAltitude: number;
  readonly ceilingAltitude: number;
  readonly initialVelocity: number;
  readonly initialFuel: number;
  readonly terrainTheme: TerrainTheme;
  readonly skyOpticalProfile: SkyOpticalProfile;
}
