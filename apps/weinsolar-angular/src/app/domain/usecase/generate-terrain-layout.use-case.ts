import { Injectable } from '@angular/core';
import { CelestialBody, CelestialBodyId } from '../models/celestial-body/celestial-body';
import {
  TerrainFeature,
  TerrainFeatureKind,
  TerrainLayout,
} from '../models/scene/terrain-layout';
import { VisualQuality } from '../models/scene/visual-quality';

const TERRAIN_SIZE_METERS = 600.0;
const PAD_RADIUS_METERS = 6.0;
const PAD_PLAIN_RADIUS_METERS = 65.0;

const WORLD_SEEDS: Record<CelestialBodyId, number> = {
  earth: 0x1a2b3c4d,
  mars: 0x2b3c4d5e,
  moon: 0x3c4d5e6f,
  titan: 0x4d5e6f70,
};

const WORLD_MAX_HEIGHTS: Record<CelestialBodyId, number> = {
  earth: 18.0,
  mars: 22.0,
  moon: 16.0,
  titan: 14.0,
};

function createMulberry32(seed: number): () => number {
  let state = seed >>> 0;
  return () => {
    state = (state + 0x6d2b79f5) >>> 0;
    let t = Math.imul(state ^ (state >>> 15), 1 | state);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function hash2d(ix: number, iz: number, seed: number): number {
  let h = (ix * 374761393 + iz * 668265263 + seed * 1442695041) | 0;
  h = Math.imul(h ^ (h >>> 13), 1274126177);
  return ((h ^ (h >>> 16)) >>> 0) / 4294967296;
}

function smoothstep(edge0: number, edge1: number, x: number): number {
  const t = Math.max(0, Math.min(1, (x - edge0) / (edge1 - edge0)));
  return t * t * (3 - 2 * t);
}

function valueNoise2d(x: number, z: number, seed: number): number {
  const xi = Math.floor(x);
  const zi = Math.floor(z);
  const xf = x - xi;
  const zf = z - zi;
  const u = xf * xf * (3 - 2 * xf);
  const v = zf * zf * (3 - 2 * zf);

  const v00 = hash2d(xi, zi, seed);
  const v10 = hash2d(xi + 1, zi, seed);
  const v01 = hash2d(xi, zi + 1, seed);
  const v11 = hash2d(xi + 1, zi + 1, seed);

  const x0 = v00 + (v10 - v00) * u;
  const x1 = v01 + (v11 - v01) * u;
  return x0 + (x1 - x0) * v;
}

function fbmNoise(x: number, z: number, seed: number): number {
  let sum = 0;
  let amp = 0.52;
  let freq = 0.012;
  for (let o = 0; o < 4; o++) {
    sum += valueNoise2d(x * freq, z * freq, seed + o * 101) * amp;
    amp *= 0.5;
    freq *= 2.1;
  }
  return sum;
}

@Injectable({ providedIn: 'root' })
export class GenerateTerrainLayoutUseCase {
  private readonly cache = new Map<string, TerrainLayout>();

  execute(world: CelestialBody, quality: VisualQuality): TerrainLayout {
    const cacheKey = `${world.id}:${quality}`;
    const cached = this.cache.get(cacheKey);
    if (cached) {
      return cached;
    }

    const resolution = quality === 'high' ? 192 : 64;
    const maxHeightMeters = WORLD_MAX_HEIGHTS[world.id];
    const seed = WORLD_SEEDS[world.id];

    // Always generate the canonical 30 features from the world seed, then slice 40% for basic
    const allFeatures = this.generateCanonicalFeatures(world.id, seed);
    const featureCount =
      quality === 'high' ? allFeatures.length : Math.round(allFeatures.length * 0.4);
    const features = allFeatures.slice(0, featureCount);

    const heights: number[] = new Array<number>(resolution * resolution);
    const half = TERRAIN_SIZE_METERS / 2;

    for (let row = 0; row < resolution; row++) {
      const z = -half + (row / (resolution - 1)) * TERRAIN_SIZE_METERS;
      for (let col = 0; col < resolution; col++) {
        const x = -half + (col / (resolution - 1)) * TERRAIN_SIZE_METERS;
        const distFromCenter = Math.sqrt(x * x + z * z);

        if (distFromCenter <= PAD_RADIUS_METERS) {
          heights[row * resolution + col] = 0;
          continue;
        }

        // Open landing plain out to 65 m so the lander never lands inside a bowl/crater,
        // transitioning smoothly to rolling hills and horizon ridges further out.
        const nearPadBlend = smoothstep(PAD_RADIUS_METERS, 22.0, distFromCenter);
        const distantHillsBlend = smoothstep(28.0, PAD_PLAIN_RADIUS_METERS * 2.2, distFromCenter);

        const baseNoise = fbmNoise(x + 300, z + 300, seed);
        const microRelief = (valueNoise2d(x * 0.08, z * 0.08, seed + 777) - 0.5) * 0.65;
        let rawH =
          microRelief * nearPadBlend +
          Math.max(0, baseNoise - 0.34) * maxHeightMeters * 1.15 * distantHillsBlend;

        if (world.id === 'mars') {
          const duneWave = Math.sin(x * 0.032 + z * 0.018) * 1.6 * distantHillsBlend;
          rawH += duneWave;
        } else if (world.id === 'titan') {
          const ridge = Math.abs(Math.sin(x * 0.022 - z * 0.026)) * 3.4 * distantHillsBlend;
          rawH += ridge;
        } else if (world.id === 'moon') {
          for (const feat of features) {
            if (feat.kind === 'crater') {
              const dx = x - feat.x;
              const dz = z - feat.z;
              const r = Math.sqrt(dx * dx + dz * dz) / feat.radius;
              if (r < 1.0) {
                rawH -= (1 - r * r) * feat.height * 0.45 * nearPadBlend;
              } else if (r < 1.35) {
                const rimT = 1 - Math.abs(r - 1.15) / 0.2;
                rawH += Math.max(0, rimT) * feat.height * 0.28 * nearPadBlend;
              }
            }
          }
        }

        heights[row * resolution + col] = Math.min(maxHeightMeters, rawH * nearPadBlend);
      }
    }

    const layout: TerrainLayout = {
      sizeMeters: TERRAIN_SIZE_METERS,
      resolution,
      maxHeightMeters,
      padRadiusMeters: PAD_RADIUS_METERS,
      heights,
      features,
    };

    this.cache.set(cacheKey, layout);
    return layout;
  }

  private generateCanonicalFeatures(
    worldId: CelestialBodyId,
    seed: number,
  ): readonly TerrainFeature[] {
    const prng = createMulberry32(seed ^ 0x9e3779b9);
    const totalCount = 30;
    const list: TerrainFeature[] = [];

    for (let i = 0; i < totalCount; i++) {
      const angle = prng() * Math.PI * 2;
      // Place features outside the open landing apron (between 20 m and 220 m)
      const distance = 20.0 + prng() * 200.0;
      const x = Math.cos(angle) * distance;
      const z = Math.sin(angle) * distance;
      const radius = 1.6 + prng() * 5.4;
      const height = 1.2 + prng() * 4.8;
      const rotationRad = prng() * Math.PI * 2;

      let kind: TerrainFeatureKind;
      if (worldId === 'earth') {
        kind = i % 2 === 0 ? 'rock' : 'vegetation';
      } else if (worldId === 'mars') {
        kind = i % 3 === 0 ? 'dune' : 'rock';
      } else if (worldId === 'moon') {
        kind = i % 4 === 0 ? 'rock' : 'crater';
      } else {
        kind = i % 3 === 0 ? 'rock' : 'iceRidge';
      }

      list.push({ kind, x, z, radius, height, rotationRad });
    }

    return list;
  }
}
