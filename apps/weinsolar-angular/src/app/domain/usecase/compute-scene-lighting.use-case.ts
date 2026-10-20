import { Injectable } from '@angular/core';
import { CelestialBody, SkyOpticalKeyframe } from '../models/celestial-body/celestial-body';
import { SceneLightingState } from '../models/scene/scene-lighting-state';
import {
  MAX_SOLAR_ELEVATION_DEG,
  MIN_SOLAR_ELEVATION_DEG,
} from '../models/simulation/solar-hour-state';

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

function smoothstep(edge0: number, edge1: number, x: number): number {
  if (edge0 === edge1) {
    return x >= edge1 ? 1 : 0;
  }
  const t = clamp((x - edge0) / (edge1 - edge0), 0, 1);
  return t * t * (3 - 2 * t);
}

function parseRgb(hex: string): [number, number, number] {
  const clean = hex.replace('#', '');
  return [
    parseInt(clean.substring(0, 2), 16),
    parseInt(clean.substring(2, 4), 16),
    parseInt(clean.substring(4, 6), 16),
  ];
}

function toHex(r: number, g: number, b: number): string {
  const clampByte = (v: number): string =>
    Math.max(0, Math.min(255, Math.round(v)))
      .toString(16)
      .padStart(2, '0')
      .toUpperCase();
  return `#${clampByte(r)}${clampByte(g)}${clampByte(b)}`;
}

function lerpHex(hexA: string, hexB: string, t: number): string {
  const [r1, g1, b1] = parseRgb(hexA);
  const [r2, g2, b2] = parseRgb(hexB);
  const f = clamp(t, 0, 1);
  return toHex(r1 + (r2 - r1) * f, g1 + (g2 - g1) * f, b1 + (b2 - b1) * f);
}

function interpolateZenithColor(
  keyframes: readonly SkyOpticalKeyframe[],
  elevationDeg: number,
): string {
  if (keyframes.length === 0) {
    return '#000000';
  }
  if (elevationDeg <= keyframes[0].elevationDeg) {
    return keyframes[0].zenithColorHex;
  }
  for (let i = 0; i < keyframes.length - 1; i++) {
    const a = keyframes[i];
    const b = keyframes[i + 1];
    if (elevationDeg >= a.elevationDeg && elevationDeg <= b.elevationDeg) {
      const span = b.elevationDeg - a.elevationDeg;
      const t = span > 0 ? (elevationDeg - a.elevationDeg) / span : 0;
      return lerpHex(a.zenithColorHex, b.zenithColorHex, t);
    }
  }
  return keyframes[keyframes.length - 1].zenithColorHex;
}

@Injectable({ providedIn: 'root' })
export class ComputeSceneLightingUseCase {
  execute(world: CelestialBody, solarElevationDeg: number): SceneLightingState {
    const clampedElevation = clamp(
      solarElevationDeg,
      MIN_SOLAR_ELEVATION_DEG,
      MAX_SOLAR_ELEVATION_DEG,
    );
    const profile = world.lightingProfile;

    const eRad = (clampedElevation * Math.PI) / 180;
    const aRad = (profile.sunAzimuthDeg * Math.PI) / 180;
    const cosE = Math.cos(eRad);
    const sinE = Math.sin(eRad);

    const sunDirection = {
      x: cosE * Math.sin(aRad),
      y: sinE,
      z: cosE * Math.cos(aRad),
    };

    // Smoothstep interpolation between sunset color (0 deg) and day color (20 deg)
    const dayBlend = smoothstep(0, 20, clampedElevation);
    const sunColorHex = lerpHex(profile.sunColorSunsetHex, profile.sunColorDayHex, dayBlend);

    let sunIntensity: number;
    let ambientIntensity: number;

    if (profile.twilightFadeDeg <= 0) {
      // Vacuum (Moon): abrupt cutoff at/below horizon (RN-14)
      sunIntensity = clampedElevation > 0 ? 1.0 : 0.0;
      ambientIntensity = 0.0;
    } else if (clampedElevation >= 0) {
      // Smooth ramp near horizon and full day intensity above 15 deg
      const horizonFactor = 0.35 + 0.65 * smoothstep(0, 18, clampedElevation);
      sunIntensity = horizonFactor;
      const ambRamp = 0.45 + 0.55 * smoothstep(0, 25, clampedElevation);
      ambientIntensity = profile.ambientDayIntensity * ambRamp;
    } else {
      // Twilight fade below horizon down to -twilightFadeDeg
      const twilightFactor = smoothstep(-profile.twilightFadeDeg, 0, clampedElevation);
      sunIntensity = 0.35 * twilightFactor;
      ambientIntensity = profile.ambientDayIntensity * 0.45 * twilightFactor;
    }

    const ambientSkyColorHex = interpolateZenithColor(
      world.skyOpticalProfile.keyframes,
      clampedElevation,
    );
    const ambientGroundColorHex = world.terrainTheme.primarySurfaceHex;
    const castsShadows = clampedElevation > 0;
    const expectedShadowLengthRatio = castsShadows ? 1 / Math.tan(eRad) : null;

    return {
      solarElevationDeg: clampedElevation,
      sunDirection,
      sunColorHex,
      sunIntensity,
      ambientSkyColorHex,
      ambientGroundColorHex,
      ambientIntensity,
      shadowSoftness: profile.shadowSoftness,
      castsShadows,
      expectedShadowLengthRatio,
    };
  }
}
