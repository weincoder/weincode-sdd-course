import { Injectable } from '@angular/core';
import { CelestialBody } from '../models/celestial-body/celestial-body';
import {
  CEILING_PROXIMITY_RATIO,
  LanderState,
  SAFE_LANDING_THRESHOLD_MPS,
} from '../models/simulation/lander-state';
import { MissionAttempt } from '../models/simulation/mission-attempt';

export const DRAG_COEFFICIENT_KD = 0.0008;
export const MAX_THRUST_ACCELERATION_MPS2 = 24.0;
export const FUEL_BURN_RATE_PERCENT_PER_SEC = 3.5;
export const MAX_REAL_DELTA_SECONDS = 0.05;

export interface SimulationStepInput {
  readonly world: CelestialBody;
  readonly state: LanderState;
  readonly attempt: MissionAttempt;
  readonly realDeltaSeconds: number;
}

export interface SimulationStepResult {
  readonly state: LanderState;
  readonly attempt: MissionAttempt;
}

@Injectable({ providedIn: 'root' })
export class SimulateDescentStepUseCase {
  createInitialState(world: CelestialBody): SimulationStepResult {
    const isVelocitySafe = Math.abs(world.initialVelocity) <= SAFE_LANDING_THRESHOLD_MPS;
    const isNearCeiling = world.initialAltitude >= CEILING_PROXIMITY_RATIO * world.ceilingAltitude;

    return {
      state: {
        altitude: world.initialAltitude,
        verticalVelocity: world.initialVelocity,
        horizontalVelocity: 0.0,
        fuelPercentage: world.initialFuel,
        isThrusterActive: false,
        status: 'descending',
        safeLandingThreshold: SAFE_LANDING_THRESHOLD_MPS,
        isVelocitySafe,
        isNearCeiling,
      },
      attempt: {
        worldId: world.id,
        outcome: 'inProgress',
        touchdownVelocity: null,
        remainingFuel: world.initialFuel,
        isSolarHourUnlocked: false,
        failureReasonEs: null,
      },
    };
  }

  computeAutopilotThruster(world: CelestialBody, state: LanderState): boolean {
    if (state.status !== 'descending' || state.fuelPercentage <= 0) {
      return false;
    }
    const netBrakeAccel = Math.max(2.0, MAX_THRUST_ACCELERATION_MPS2 - world.gravity);
    const stoppingDistance =
      state.verticalVelocity < -1.2
        ? Math.max(0, state.verticalVelocity * state.verticalVelocity - 1.2 * 1.2) /
          (2 * netBrakeAccel)
        : 0.0;

    if (state.altitude <= stoppingDistance + 18.0) {
      return state.verticalVelocity < -1.3;
    }
    return state.verticalVelocity < -28.0;
  }

  isAutopilotRecoverable(world: CelestialBody, state: LanderState): boolean {
    if (state.fuelPercentage < 15.0) {
      return false;
    }
    const netBrakeAccel = Math.max(2.0, MAX_THRUST_ACCELERATION_MPS2 - world.gravity);
    const stoppingDistance =
      state.verticalVelocity < -1.5
        ? Math.max(0, state.verticalVelocity * state.verticalVelocity - 1.5 * 1.5) /
          (2 * netBrakeAccel)
        : 0.0;
    return state.altitude > stoppingDistance + 6.0;
  }

  step(input: SimulationStepInput): SimulationStepResult {
    const { world, state, attempt } = input;
    if (attempt.outcome !== 'inProgress' || state.status !== 'descending') {
      return { state, attempt };
    }

    const clampedRealDt = Math.max(0, Math.min(input.realDeltaSeconds, MAX_REAL_DELTA_SECONDS));
    if (clampedRealDt === 0) {
      return { state, attempt };
    }

    const simDt = clampedRealDt * world.timeScale;

    const hasFuel = state.fuelPercentage > 0;
    const effectiveThruster = state.isThrusterActive && hasFuel;

    const gravityAccel = -world.gravity;
    const dragAccel =
      world.atmosphericDensity === 0
        ? 0.0
        : -Math.sign(state.verticalVelocity) *
          DRAG_COEFFICIENT_KD *
          world.atmosphericDensity *
          state.verticalVelocity *
          state.verticalVelocity;
    const thrustAccel = effectiveThruster ? MAX_THRUST_ACCELERATION_MPS2 : 0.0;

    const netAcceleration = gravityAccel + dragAccel + thrustAccel;
    const nextVelocity = state.verticalVelocity + netAcceleration * simDt;
    const rawNextAltitude = state.altitude + nextVelocity * simDt;

    const nextFuel = effectiveThruster
      ? Math.max(0.0, state.fuelPercentage - FUEL_BURN_RATE_PERCENT_PER_SEC * simDt)
      : state.fuelPercentage;

    const nextThrusterActive = effectiveThruster && nextFuel > 0;

    if (rawNextAltitude > world.ceilingAltitude) {
      const lostState: LanderState = {
        altitude: rawNextAltitude,
        verticalVelocity: nextVelocity,
        horizontalVelocity: 0.0,
        fuelPercentage: nextFuel,
        isThrusterActive: false,
        status: 'lostSignal',
        safeLandingThreshold: SAFE_LANDING_THRESHOLD_MPS,
        isVelocitySafe: Math.abs(nextVelocity) <= SAFE_LANDING_THRESHOLD_MPS,
        isNearCeiling: true,
      };
      const lostAttempt: MissionAttempt = {
        worldId: world.id,
        outcome: 'failedSignalLost',
        touchdownVelocity: null,
        remainingFuel: nextFuel,
        isSolarHourUnlocked: false,
        failureReasonEs: 'Misión fallida – señal perdida',
      };
      return { state: lostState, attempt: lostAttempt };
    }

    if (rawNextAltitude <= 0.0) {
      const impactSpeed = Math.abs(nextVelocity);
      const isSafeTouchdown = impactSpeed <= SAFE_LANDING_THRESHOLD_MPS;

      const landedState: LanderState = {
        altitude: 0.0,
        verticalVelocity: nextVelocity,
        horizontalVelocity: 0.0,
        fuelPercentage: nextFuel,
        isThrusterActive: false,
        status: isSafeTouchdown ? 'landed' : 'crashed',
        safeLandingThreshold: SAFE_LANDING_THRESHOLD_MPS,
        isVelocitySafe: isSafeTouchdown,
        isNearCeiling: false,
      };

      const completedAttempt: MissionAttempt = {
        worldId: world.id,
        outcome: isSafeTouchdown ? 'success' : 'failedImpact',
        touchdownVelocity: nextVelocity,
        remainingFuel: nextFuel,
        isSolarHourUnlocked: isSafeTouchdown,
        failureReasonEs: isSafeTouchdown
          ? null
          : `Misión fallida – Velocidad de impacto (${impactSpeed.toFixed(1)} m/s) superó el umbral estructural de 2,0 m/s`,
      };

      return { state: landedState, attempt: completedAttempt };
    }

    const descendingState: LanderState = {
      altitude: rawNextAltitude,
      verticalVelocity: nextVelocity,
      horizontalVelocity: 0.0,
      fuelPercentage: nextFuel,
      isThrusterActive: nextThrusterActive,
      status: 'descending',
      safeLandingThreshold: SAFE_LANDING_THRESHOLD_MPS,
      isVelocitySafe: Math.abs(nextVelocity) <= SAFE_LANDING_THRESHOLD_MPS,
      isNearCeiling: rawNextAltitude >= CEILING_PROXIMITY_RATIO * world.ceilingAltitude,
    };

    const inProgressAttempt: MissionAttempt = {
      ...attempt,
      remainingFuel: nextFuel,
    };

    return { state: descendingState, attempt: inProgressAttempt };
  }
}
