import { Injectable } from '@angular/core';
import { CelestialBody, SkyOpticalKeyframe } from '../models/celestial-body/celestial-body';
import { MissionAttempt } from '../models/simulation/mission-attempt';
import {
  INITIAL_SOLAR_ELEVATION_DEG,
  MAX_SOLAR_ELEVATION_DEG,
  MIN_SOLAR_ELEVATION_DEG,
  SolarHourState,
} from '../models/simulation/solar-hour-state';

const FORBIDDEN_WEINCODE_HEX = new Set(['#18084D', '#5236FF', '#A599FF', '#FFFFFF']);

export interface EvaluateSolarHourInput {
  readonly world: CelestialBody;
  readonly attempt: MissionAttempt;
  readonly solarElevationDeg: number;
  readonly cameraAzimuthDeg: number;
}

@Injectable({ providedIn: 'root' })
export class EvaluateSolarHourUseCase {
  evaluate(input: EvaluateSolarHourInput): SolarHourState {
    const isUnlocked = input.attempt.outcome === 'success' && input.attempt.isSolarHourUnlocked;
    const effectiveElevation = isUnlocked
      ? this.clamp(input.solarElevationDeg, MIN_SOLAR_ELEVATION_DEG, MAX_SOLAR_ELEVATION_DEG)
      : INITIAL_SOLAR_ELEVATION_DEG;
    const normalizedAzimuth = isUnlocked ? ((input.cameraAzimuthDeg % 360) + 360) % 360 : 0.0;

    const profile = input.world.skyOpticalProfile;
    const interpolated = this.interpolateKeyframes(profile.keyframes, effectiveElevation);

    const directLightIntensity = !profile.hasAtmosphere
      ? effectiveElevation < 0
        ? 0.0
        : 1.0
      : effectiveElevation < -6
        ? 0.0
        : this.clamp((effectiveElevation + 6) / 45, 0.05, 1.0);

    return {
      isUnlocked,
      solarElevationDeg: effectiveElevation,
      cameraAzimuthDeg: normalizedAzimuth,
      zenithColorHex: this.sanitizeSceneHex(interpolated.zenithColorHex),
      horizonColorHex: this.sanitizeSceneHex(interpolated.horizonColorHex),
      sunHaloColorHex: this.sanitizeSceneHex(interpolated.sunHaloColorHex),
      sunDiscColorHex: this.sanitizeSceneHex(interpolated.sunDiscColorHex),
      shadowHardness: profile.shadowHardness,
      ambientLightIntensity: profile.hasAtmosphere ? interpolated.ambientLightIntensity : 0.0,
      directLightIntensity,
    };
  }

  private interpolateKeyframes(
    keyframes: readonly SkyOpticalKeyframe[],
    elevationDeg: number,
  ): SkyOpticalKeyframe {
    if (keyframes.length === 0) {
      return {
        elevationDeg,
        zenithColorHex: '#000000',
        horizonColorHex: '#000000',
        sunHaloColorHex: '#000000',
        sunDiscColorHex: '#FFFDF4',
        ambientLightIntensity: 0,
      };
    }

    const sorted = [...keyframes].sort((a, b) => a.elevationDeg - b.elevationDeg);
    if (elevationDeg <= sorted[0].elevationDeg) {
      return sorted[0];
    }
    if (elevationDeg >= sorted[sorted.length - 1].elevationDeg) {
      return sorted[sorted.length - 1];
    }

    for (let i = 0; i < sorted.length - 1; i++) {
      const lower = sorted[i];
      const upper = sorted[i + 1];
      if (elevationDeg >= lower.elevationDeg && elevationDeg <= upper.elevationDeg) {
        const span = upper.elevationDeg - lower.elevationDeg;
        const t = span === 0 ? 0 : (elevationDeg - lower.elevationDeg) / span;
        return {
          elevationDeg,
          zenithColorHex: this.lerpHex(lower.zenithColorHex, upper.zenithColorHex, t),
          horizonColorHex: this.lerpHex(lower.horizonColorHex, upper.horizonColorHex, t),
          sunHaloColorHex: this.lerpHex(lower.sunHaloColorHex, upper.sunHaloColorHex, t),
          sunDiscColorHex: this.lerpHex(lower.sunDiscColorHex, upper.sunDiscColorHex, t),
          ambientLightIntensity:
            lower.ambientLightIntensity +
            (upper.ambientLightIntensity - lower.ambientLightIntensity) * t,
        };
      }
    }

    return sorted[sorted.length - 1];
  }

  private lerpHex(hexA: string, hexB: string, t: number): string {
    const a = this.hexToRgb(hexA);
    const b = this.hexToRgb(hexB);
    const r = Math.round(a.r + (b.r - a.r) * t);
    const g = Math.round(a.g + (b.g - a.g) * t);
    const bl = Math.round(a.b + (b.b - a.b) * t);
    return this.rgbToHex(r, g, bl);
  }

  private sanitizeSceneHex(hex: string): string {
    const upper = hex.toUpperCase();
    if (!FORBIDDEN_WEINCODE_HEX.has(upper)) {
      return upper;
    }
    const rgb = this.hexToRgb(upper);
    const adjustedB = rgb.b > 0 ? rgb.b - 1 : 1;
    return this.rgbToHex(rgb.r, rgb.g, adjustedB);
  }

  private hexToRgb(hex: string): { r: number; g: number; b: number } {
    const clean = hex.replace('#', '');
    return {
      r: parseInt(clean.substring(0, 2), 16) || 0,
      g: parseInt(clean.substring(2, 4), 16) || 0,
      b: parseInt(clean.substring(4, 6), 16) || 0,
    };
  }

  private rgbToHex(r: number, g: number, b: number): string {
    const toHex = (n: number) => Math.max(0, Math.min(255, n)).toString(16).padStart(2, '0');
    return `#${toHex(r)}${toHex(g)}${toHex(b)}`.toUpperCase();
  }

  private clamp(val: number, min: number, max: number): number {
    return Math.max(min, Math.min(max, val));
  }
}
