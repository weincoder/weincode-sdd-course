export const INITIAL_SOLAR_ELEVATION_DEG = 65.0;
export const MIN_SOLAR_ELEVATION_DEG = -10.0;
export const MAX_SOLAR_ELEVATION_DEG = 90.0;

export interface SolarHourState {
  readonly isUnlocked: boolean;
  readonly solarElevationDeg: number;
  readonly cameraAzimuthDeg: number;
  readonly zenithColorHex: string;
  readonly horizonColorHex: string;
  readonly sunHaloColorHex: string;
  readonly sunDiscColorHex: string;
  readonly shadowHardness: number;
  readonly ambientLightIntensity: number;
  readonly directLightIntensity: number;
}
