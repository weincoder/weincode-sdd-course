export interface Vector3Like {
  readonly x: number;
  readonly y: number;
  readonly z: number;
}

export interface SceneLightingState {
  readonly solarElevationDeg: number;
  readonly sunDirection: Vector3Like;
  readonly sunColorHex: string;
  readonly sunIntensity: number;
  readonly ambientSkyColorHex: string;
  readonly ambientGroundColorHex: string;
  readonly ambientIntensity: number;
  readonly shadowSoftness: number;
  readonly castsShadows: boolean;
  readonly expectedShadowLengthRatio: number | null;
}
