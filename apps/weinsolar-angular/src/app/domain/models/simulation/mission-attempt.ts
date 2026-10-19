import { CelestialBodyId } from '../celestial-body/celestial-body';

export type MissionOutcome =
  | 'inProgress'
  | 'success'
  | 'failedImpact'
  | 'failedSignalLost'
  | 'abandoned';

export interface MissionAttempt {
  readonly worldId: CelestialBodyId;
  readonly outcome: MissionOutcome;
  readonly touchdownVelocity: number | null;
  readonly remainingFuel: number;
  readonly isSolarHourUnlocked: boolean;
  readonly failureReasonEs: string | null;
}
