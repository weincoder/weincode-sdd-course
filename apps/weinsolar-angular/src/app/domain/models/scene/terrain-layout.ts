export type TerrainFeatureKind = 'rock' | 'crater' | 'dune' | 'iceRidge' | 'vegetation';

export interface TerrainFeature {
  readonly kind: TerrainFeatureKind;
  readonly x: number;
  readonly z: number;
  readonly radius: number;
  readonly height: number;
  readonly rotationRad: number;
}

export interface TerrainLayout {
  readonly sizeMeters: number;
  readonly resolution: number;
  readonly maxHeightMeters: number;
  readonly padRadiusMeters: number;
  readonly heights: readonly number[];
  readonly features: readonly TerrainFeature[];
}
