import { TestBed } from '@angular/core/testing';
import { firstValueFrom } from 'rxjs';
import { CelestialBodyLocalAdapter } from '../../infraestructure/driven-adapter/celestial-body-local/celestial-body-local.adapter';
import { CelestialBody } from '../models/celestial-body/celestial-body';
import { CelestialBodyGateway } from '../models/celestial-body/gateway/celestial-body-gateway';
import { LanderState } from '../models/simulation/lander-state';
import { GetCelestialBodiesUseCase } from './get-celestial-bodies.use-case';
import {
  MAX_THRUST_ACCELERATION_MPS2,
  SimulateDescentStepUseCase,
} from './simulate-descent-step.use-case';
import referenceTrajectories from './__fixtures__/reference-trajectories.json';

const PRINT_FIXTURES = false;

type ThrustProfileFn = (
  tick: number,
  world: CelestialBody,
  state: LanderState,
  useCase: SimulateDescentStepUseCase,
) => boolean;

interface ReferenceSample {
  readonly tick: number;
  readonly altitude: number;
  readonly verticalVelocity: number;
  readonly horizontalVelocity: number;
  readonly fuelPercentage: number;
  readonly isThrusterActive: boolean;
  readonly status: string;
}

interface ReferenceTrajectory {
  readonly worldId: string;
  readonly profile: string;
  readonly finalAttempt: {
    readonly worldId: string;
    readonly outcome: string;
    readonly touchdownVelocity: number | null;
    readonly remainingFuel: number;
    readonly isSolarHourUnlocked: boolean;
    readonly failureReasonEs: string | null;
  };
  readonly samples: readonly ReferenceSample[];
}

function impactTargetThruster(world: CelestialBody, state: LanderState): boolean {
  if (state.status !== 'descending' || state.fuelPercentage <= 0) {
    return false;
  }
  const netBrakeAccel = Math.max(2.0, MAX_THRUST_ACCELERATION_MPS2 - world.gravity);
  const targetImpactSpeed = 2.4;
  const stoppingDistance =
    state.verticalVelocity < -targetImpactSpeed
      ? Math.max(
          0,
          state.verticalVelocity * state.verticalVelocity - targetImpactSpeed * targetImpactSpeed,
        ) /
        (2 * netBrakeAccel)
      : 0.0;
  if (state.altitude <= stoppingDistance + 18.0) {
    return state.verticalVelocity < -targetImpactSpeed;
  }
  return state.verticalVelocity < -28.0;
}

describe('Reference trajectories v1 (T003 — SC-003, RN-09)', () => {
  let useCase: SimulateDescentStepUseCase;
  let getBodiesUseCase: GetCelestialBodiesUseCase;
  let worlds: CelestialBody[];

  const fixedDt = 1 / 60;
  const maxTicks = 4000;
  const sampleInterval = 30;
  const tolerance = 1e-9;

  const profiles: Record<string, ThrustProfileFn> = {
    a_free_fall: () => false,
    b_continuous_ceiling_escape: () => true,
    c_safe_touchdown_le_2_0: (_tick, world, state, uc) => uc.computeAutopilotThruster(world, state),
    d_impact_touchdown_gt_2_0: (_tick, world, state) => impactTargetThruster(world, state),
    e_alternating_pulses_0_5s: (tick) => Math.floor(tick / 30) % 2 === 0,
  };

  beforeEach(async () => {
    TestBed.configureTestingModule({
      providers: [
        SimulateDescentStepUseCase,
        GetCelestialBodiesUseCase,
        { provide: CelestialBodyGateway, useClass: CelestialBodyLocalAdapter },
      ],
    });
    useCase = TestBed.inject(SimulateDescentStepUseCase);
    getBodiesUseCase = TestBed.inject(GetCelestialBodiesUseCase);
    worlds = await firstValueFrom(getBodiesUseCase.getAll());
  });

  it('should match all 5 thrust profiles across all 4 worlds within 1e-9 tolerance', () => {
    const computedMap: Record<string, ReferenceTrajectory> = {};

    for (const world of worlds) {
      for (const [profileName, profileFn] of Object.entries(profiles)) {
        const key = `${world.id}__${profileName}`;
        let { state, attempt } = useCase.createInitialState(world);
        const samples: ReferenceSample[] = [];

        for (let tick = 0; tick < maxTicks && state.status === 'descending'; tick++) {
          const thrusterActive = profileFn(tick, world, state, useCase);
          state = { ...state, isThrusterActive: thrusterActive };
          const next = useCase.step({
            world,
            state,
            attempt,
            realDeltaSeconds: fixedDt,
          });
          state = next.state;
          attempt = next.attempt;

          if (tick % sampleInterval === 0 || state.status !== 'descending') {
            samples.push({
              tick,
              altitude: state.altitude,
              verticalVelocity: state.verticalVelocity,
              horizontalVelocity: state.horizontalVelocity,
              fuelPercentage: state.fuelPercentage,
              isThrusterActive: state.isThrusterActive,
              status: state.status,
            });
          }
        }

        computedMap[key] = {
          worldId: world.id,
          profile: profileName,
          finalAttempt: {
            worldId: attempt.worldId,
            outcome: attempt.outcome,
            touchdownVelocity: attempt.touchdownVelocity,
            remainingFuel: attempt.remainingFuel,
            isSolarHourUnlocked: attempt.isSolarHourUnlocked,
            failureReasonEs: attempt.failureReasonEs,
          },
          samples,
        };
      }
    }

    if (PRINT_FIXTURES) {
      // eslint-disable-next-line no-console
      console.log(JSON.stringify(computedMap, null, 2));
    }

    const expectedMap = referenceTrajectories as unknown as Record<string, ReferenceTrajectory>;
    expect(Object.keys(computedMap)).toEqual(Object.keys(expectedMap));

    for (const key of Object.keys(expectedMap)) {
      const expected = expectedMap[key];
      const actual = computedMap[key];

      expect(actual.finalAttempt.outcome)
        .withContext(`${key} finalAttempt.outcome`)
        .toBe(expected.finalAttempt.outcome);
      expect(actual.finalAttempt.isSolarHourUnlocked)
        .withContext(`${key} finalAttempt.isSolarHourUnlocked`)
        .toBe(expected.finalAttempt.isSolarHourUnlocked);

      if (expected.finalAttempt.touchdownVelocity === null) {
        expect(actual.finalAttempt.touchdownVelocity)
          .withContext(`${key} touchdownVelocity`)
          .toBeNull();
      } else {
        expect(
          Math.abs(
            (actual.finalAttempt.touchdownVelocity ?? 0) - expected.finalAttempt.touchdownVelocity,
          ),
        )
          .withContext(`${key} touchdownVelocity`)
          .toBeLessThanOrEqual(tolerance);
      }

      expect(Math.abs(actual.finalAttempt.remainingFuel - expected.finalAttempt.remainingFuel))
        .withContext(`${key} remainingFuel`)
        .toBeLessThanOrEqual(tolerance);

      expect(actual.samples.length)
        .withContext(`${key} sample count`)
        .toBe(expected.samples.length);

      for (let i = 0; i < expected.samples.length; i++) {
        const expSample = expected.samples[i];
        const actSample = actual.samples[i];

        expect(actSample.tick).withContext(`${key} tick at sample ${i}`).toBe(expSample.tick);
        expect(Math.abs(actSample.altitude - expSample.altitude))
          .withContext(`${key} altitude at sample ${i}`)
          .toBeLessThanOrEqual(tolerance);
        expect(Math.abs(actSample.verticalVelocity - expSample.verticalVelocity))
          .withContext(`${key} verticalVelocity at sample ${i}`)
          .toBeLessThanOrEqual(tolerance);
        expect(Math.abs(actSample.fuelPercentage - expSample.fuelPercentage))
          .withContext(`${key} fuelPercentage at sample ${i}`)
          .toBeLessThanOrEqual(tolerance);
        expect(actSample.status).withContext(`${key} status at sample ${i}`).toBe(expSample.status);
      }
    }
  });
});
