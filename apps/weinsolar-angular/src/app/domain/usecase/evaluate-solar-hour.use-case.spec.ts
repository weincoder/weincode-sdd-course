import { TestBed } from '@angular/core/testing';
import { firstValueFrom } from 'rxjs';
import { CelestialBodyLocalAdapter } from '../../infraestructure/driven-adapter/celestial-body-local/celestial-body-local.adapter';
import { CelestialBody } from '../models/celestial-body/celestial-body';
import { MissionAttempt } from '../models/simulation/mission-attempt';
import { EvaluateSolarHourUseCase } from './evaluate-solar-hour.use-case';

const WEINCODE_HUD_HEX = new Set(['#18084D', '#5236FF', '#A599FF', '#FFFFFF']);

function parseRgb(hex: string): { r: number; g: number; b: number } {
  const clean = hex.replace('#', '');
  return {
    r: parseInt(clean.substring(0, 2), 16),
    g: parseInt(clean.substring(2, 4), 16),
    b: parseInt(clean.substring(4, 6), 16),
  };
}

describe('EvaluateSolarHourUseCase (T041 — RN-06, RN-08, FR-012, FR-015, FR-021, FR-030, SC-004)', () => {
  let useCase: EvaluateSolarHourUseCase;
  let worldsById: Record<string, CelestialBody>;

  beforeEach(async () => {
    TestBed.configureTestingModule({
      providers: [EvaluateSolarHourUseCase, CelestialBodyLocalAdapter],
    });
    useCase = TestBed.inject(EvaluateSolarHourUseCase);
    const adapter = TestBed.inject(CelestialBodyLocalAdapter);
    const list = await firstValueFrom(adapter.getAll());
    worldsById = {
      earth: list.find((w) => w.id === 'earth')!,
      mars: list.find((w) => w.id === 'mars')!,
      moon: list.find((w) => w.id === 'moon')!,
      titan: list.find((w) => w.id === 'titan')!,
    };
  });

  it('should strictly lock Solar Hour when mission outcome is not "success" (RN-06, FR-012, SC-004)', () => {
    const earth = worldsById['earth'];
    const failedOutcomes: MissionAttempt['outcome'][] = [
      'inProgress',
      'failedImpact',
      'failedSignalLost',
      'abandoned',
    ];

    for (const outcome of failedOutcomes) {
      const attempt: MissionAttempt = {
        worldId: 'earth',
        outcome,
        touchdownVelocity: outcome === 'failedImpact' ? -5.2 : null,
        remainingFuel: 40,
        isSolarHourUnlocked: false,
        failureReasonEs: 'Fallo',
      };

      const state = useCase.evaluate({
        world: earth,
        attempt,
        solarElevationDeg: 8,
        cameraAzimuthDeg: 120,
      });

      expect(state.isUnlocked).toBe(false);
      // Should ignore the requested 8 deg and remain at default 65 deg when locked
      expect(state.solarElevationDeg).toBe(65);
    }
  });

  it('should transition Earth horizon from daytime blue (65°) to warm orange/red at sunset (5°) (FR-015)', () => {
    const earth = worldsById['earth'];
    const successAttempt: MissionAttempt = {
      worldId: 'earth',
      outcome: 'success',
      touchdownVelocity: -1.4,
      remainingFuel: 52,
      isSolarHourUnlocked: true,
      failureReasonEs: null,
    };

    const dayState = useCase.evaluate({
      world: earth,
      attempt: successAttempt,
      solarElevationDeg: 65,
      cameraAzimuthDeg: 0,
    });
    const sunsetState = useCase.evaluate({
      world: earth,
      attempt: successAttempt,
      solarElevationDeg: 5,
      cameraAzimuthDeg: 0,
    });

    const dayHorizon = parseRgb(dayState.horizonColorHex);
    const sunsetHorizon = parseRgb(sunsetState.horizonColorHex);

    expect(dayHorizon.b).toBeGreaterThan(dayHorizon.r);
    expect(sunsetHorizon.r).toBeGreaterThan(sunsetHorizon.b);
  });

  it('should produce an ochre Martian sky with a cold blue circumsolar halo (B > R) near sunset (FR-015)', () => {
    const mars = worldsById['mars'];
    const successAttempt: MissionAttempt = {
      worldId: 'mars',
      outcome: 'success',
      touchdownVelocity: -1.6,
      remainingFuel: 48,
      isSolarHourUnlocked: true,
      failureReasonEs: null,
    };

    const sunsetMars = useCase.evaluate({
      world: mars,
      attempt: successAttempt,
      solarElevationDeg: 6,
      cameraAzimuthDeg: 45,
    });

    const haloRgb = parseRgb(sunsetMars.sunHaloColorHex);
    const horizonRgb = parseRgb(sunsetMars.horizonColorHex);

    expect(haloRgb.b).toBeGreaterThan(haloRgb.r);
    expect(horizonRgb.r).toBeGreaterThan(horizonRgb.b);
  });

  it('should maintain permanent black sky (#000000), zero ambient light, shadowHardness === 1.0, and abrupt direct light cutoff (< 0°) on the Moon (FR-015, FR-030)', () => {
    const moon = worldsById['moon'];
    const successAttempt: MissionAttempt = {
      worldId: 'moon',
      outcome: 'success',
      touchdownVelocity: -1.1,
      remainingFuel: 60,
      isSolarHourUnlocked: true,
      failureReasonEs: null,
    };

    for (const angle of [65, 10, -5]) {
      const state = useCase.evaluate({
        world: moon,
        attempt: successAttempt,
        solarElevationDeg: angle,
        cameraAzimuthDeg: 0,
      });
      expect(state.zenithColorHex).toBe('#000000');
      expect(state.horizonColorHex).toBe('#000000');
      expect(state.ambientLightIntensity).toBe(0);
      expect(state.shadowHardness).toBe(1.0);

      if (angle < 0) {
        expect(state.directLightIntensity).toBe(0);
      } else {
        expect(state.directLightIntensity).toBeGreaterThan(0);
      }
    }
  });

  it('should produce dense amber haze with diffuse shadows (shadowHardness <= 0.2) on Titan (FR-015, FR-030)', () => {
    const titan = worldsById['titan'];
    const successAttempt: MissionAttempt = {
      worldId: 'titan',
      outcome: 'success',
      touchdownVelocity: -0.9,
      remainingFuel: 70,
      isSolarHourUnlocked: true,
      failureReasonEs: null,
    };

    const state = useCase.evaluate({
      world: titan,
      attempt: successAttempt,
      solarElevationDeg: 15,
      cameraAzimuthDeg: 180,
    });

    const horizonRgb = parseRgb(state.horizonColorHex);
    expect(state.shadowHardness).toBeLessThanOrEqual(0.2);
    expect(horizonRgb.r).toBeGreaterThan(horizonRgb.g);
    expect(horizonRgb.g).toBeGreaterThan(horizonRgb.b);
  });

  it('should never emit any Weincode HUD palette color (#18084D, #5236FF, #A599FF, #FFFFFF) in sky or terrain across [-10°, 90°] (RN-08, FR-021)', () => {
    for (const world of Object.values(worldsById)) {
      const theme = world.terrainTheme;
      expect(WEINCODE_HUD_HEX.has(theme.primarySurfaceHex.toUpperCase())).toBe(false);
      expect(WEINCODE_HUD_HEX.has(theme.secondarySurfaceHex.toUpperCase())).toBe(false);
      expect(WEINCODE_HUD_HEX.has(theme.featureColorHex.toUpperCase())).toBe(false);
      expect(WEINCODE_HUD_HEX.has(theme.accentFeatureColorHex.toUpperCase())).toBe(false);

      const attempt: MissionAttempt = {
        worldId: world.id,
        outcome: 'success',
        touchdownVelocity: -1.0,
        remainingFuel: 50,
        isSolarHourUnlocked: true,
        failureReasonEs: null,
      };

      for (let angle = -10; angle <= 90; angle += 5) {
        const solarState = useCase.evaluate({
          world,
          attempt,
          solarElevationDeg: angle,
          cameraAzimuthDeg: 0,
        });
        expect(WEINCODE_HUD_HEX.has(solarState.zenithColorHex.toUpperCase())).toBe(false);
        expect(WEINCODE_HUD_HEX.has(solarState.horizonColorHex.toUpperCase())).toBe(false);
        expect(WEINCODE_HUD_HEX.has(solarState.sunHaloColorHex.toUpperCase())).toBe(false);
        expect(WEINCODE_HUD_HEX.has(solarState.sunDiscColorHex.toUpperCase())).toBe(false);
      }
    }
  });
});
