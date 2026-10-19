export type LanderStatus = 'descending' | 'landed' | 'crashed' | 'lostSignal';

export const SAFE_LANDING_THRESHOLD_MPS = 2.0;
export const CEILING_PROXIMITY_RATIO = 0.85;

export interface LanderState {
  readonly altitude: number;
  readonly verticalVelocity: number;
  readonly horizontalVelocity: number;
  readonly fuelPercentage: number;
  readonly isThrusterActive: boolean;
  readonly status: LanderStatus;
  readonly safeLandingThreshold: number;
  readonly isVelocitySafe: boolean;
  readonly isNearCeiling: boolean;
}
