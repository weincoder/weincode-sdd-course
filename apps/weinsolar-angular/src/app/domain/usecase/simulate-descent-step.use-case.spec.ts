import { TestBed } from '@angular/core/testing';
import { firstValueFrom } from 'rxjs';
import { CelestialBodyLocalAdapter } from '../../infraestructure/driven-adapter/celestial-body-local/celestial-body-local.adapter';
import { CelestialBody } from '../models/celestial-body/celestial-body';
import { SimulateDescentStepUseCase } from './simulate-descent-step.use-case';

describe('SimulateDescentStepUseCase (T028 — RN-01..RN-05, RN-07, SC-002, SC-004)', () => {
  let useCase: SimulateDescentStepUseCase;
  let adapter: CelestialBodyLocalAdapter;
  let worldsById: Record<string, CelestialBody>;

  beforeEach(async () => {
    TestBed.configureTestingModule({
      providers: [SimulateDescentStepUseCase, CelestialBodyLocalAdapter],
    });
    useCase = TestBed.inject(SimulateDescentStepUseCase);
    adapter = TestBed.inject(CelestialBodyLocalAdapter);
    const list = await firstValueFrom(adapter.getAll());
    worldsById = {
      earth: list.find((w) => w.id === 'earth')!,
      mars: list.find((w) => w.id === 'mars')!,
      moon: list.find((w) => w.id === 'moon')!,
      titan: list.find((w) => w.id === 'titan')!,
    };
  });

  it('should accelerate downward under real world gravity when thruster is off (FR-003, FR-004)', () => {
    const mars = worldsById['mars'];
    const initial = useCase.createInitialState(mars);
    const result = useCase.step({
      world: mars,
      state: initial.state,
      attempt: initial.attempt,
      realDeltaSeconds: 0.01,
    });

    expect(result.state.verticalVelocity).toBeLessThan(initial.state.verticalVelocity);
    expect(result.state.altitude).toBeLessThan(initial.state.altitude);
    expect(result.state.horizontalVelocity).toBe(0);
  });

  it('should apply zero aerodynamic drag on the Moon (RN-02, FR-005) and noticeable quadratic drag on Earth/Titan', () => {
    const moon = worldsById['moon'];
    const titan = worldsById['titan'];

    // Moon has rho = 0 and timeScale = 4. For realDeltaSeconds = 0.01 -> simDt = 0.04 s
    const moonInit = useCase.createInitialState(moon);
    const moonStep = useCase.step({
      world: moon,
      state: moonInit.state,
      attempt: moonInit.attempt,
      realDeltaSeconds: 0.01,
    });
    const expectedMoonVy = moon.initialVelocity - moon.gravity * (0.01 * moon.timeScale);
    expect(moonStep.state.verticalVelocity).toBeCloseTo(expectedMoonVy, 6);

    // Compare free fall from identical altitude & initial velocity on Moon vs Titan
    const customMoonState = {
      ...moonInit.state,
      altitude: 400,
      verticalVelocity: -25.0,
    };
    const customTitanInit = useCase.createInitialState(titan);
    const customTitanState = {
      ...customTitanInit.state,
      altitude: 400,
      verticalVelocity: -25.0,
    };

    const moonNext = useCase.step({
      world: moon,
      state: customMoonState,
      attempt: moonInit.attempt,
      realDeltaSeconds: 0.01,
    });
    const titanNext = useCase.step({
      world: titan,
      state: customTitanState,
      attempt: customTitanInit.attempt,
      realDeltaSeconds: 0.01,
    });

    // On Titan (rho = 5.3), upward quadratic drag at v = -25 m/s is:
    // a_drag = +0.0008 * 5.3 * 625 = +2.65 m/s^2 > g_titan (1.352 m/s^2), so it actually decelerates!
    expect(Math.abs(titanNext.state.verticalVelocity)).toBeLessThan(25.0);
    expect(Math.abs(moonNext.state.verticalVelocity)).toBeGreaterThan(25.0);
  });

  it('should decelerate fall and consume proportional fuel when thruster is active (FR-006)', () => {
    const earth = worldsById['earth'];
    const initial = useCase.createInitialState(earth);
    const stateWithThruster = { ...initial.state, isThrusterActive: true };

    const result = useCase.step({
      world: earth,
      state: stateWithThruster,
      attempt: initial.attempt,
      realDeltaSeconds: 0.02, // simDt = 0.04 s on Earth (timeScale = 2)
    });

    // Net upward acceleration: 24.0 - 9.81 + drag > 0 -> velocity becomes less negative
    expect(result.state.verticalVelocity).toBeGreaterThan(initial.state.verticalVelocity);
    // Fuel consumption: 3.5 %/s * 0.04 s = 0.14%
    expect(result.state.fuelPercentage).toBeCloseTo(100 - 3.5 * 0.04, 5);
  });

  it('should cut thrust completely and keep fuel at 0 when fuelPercentage is 0 (RN-03, FR-007)', () => {
    const moon = worldsById['moon'];
    const initial = useCase.createInitialState(moon);
    const emptyFuelState = {
      ...initial.state,
      fuelPercentage: 0,
      isThrusterActive: true,
    };

    const result = useCase.step({
      world: moon,
      state: emptyFuelState,
      attempt: initial.attempt,
      realDeltaSeconds: 0.01,
    });

    const expectedFreeFallVy = moon.initialVelocity - moon.gravity * (0.01 * moon.timeScale);
    expect(result.state.fuelPercentage).toBe(0);
    expect(result.state.isThrusterActive).toBe(false);
    expect(result.state.verticalVelocity).toBeCloseTo(expectedFreeFallVy, 6);
  });

  it('should evaluate exact landing threshold: |v_y| === 2.0 m/s -> success, |v_y| === 2.1 m/s -> failedImpact (RN-04, FR-009, FR-010, SC-004)', () => {
    const moon = worldsById['moon'];
    const initial = useCase.createInitialState(moon);

    // Case 1: Touchdown at exactly -2.0 m/s
    // Set velocity slightly above -2.0 so after tiny step it hits surface at -2.0 m/s
    const simDt = 0.001 * moon.timeScale; // 0.004 s
    const preTouchdownSafeVy = -2.0 + moon.gravity * simDt;
    const safeResult = useCase.step({
      world: moon,
      state: {
        ...initial.state,
        altitude: 0.001,
        verticalVelocity: preTouchdownSafeVy,
        isThrusterActive: false,
      },
      attempt: initial.attempt,
      realDeltaSeconds: 0.001,
    });

    expect(safeResult.state.altitude).toBe(0);
    expect(safeResult.state.status).toBe('landed');
    expect(safeResult.attempt.outcome).toBe('success');
    expect(safeResult.attempt.isSolarHourUnlocked).toBe(true);
    expect(Math.abs(safeResult.attempt.touchdownVelocity!)).toBeCloseTo(2.0, 4);

    // Case 2: Touchdown at -2.1 m/s
    const preTouchdownCrashVy = -2.1 + moon.gravity * simDt;
    const crashResult = useCase.step({
      world: moon,
      state: {
        ...initial.state,
        altitude: 0.001,
        verticalVelocity: preTouchdownCrashVy,
        isThrusterActive: false,
      },
      attempt: initial.attempt,
      realDeltaSeconds: 0.001,
    });

    expect(crashResult.state.altitude).toBe(0);
    expect(crashResult.state.status).toBe('crashed');
    expect(crashResult.attempt.outcome).toBe('failedImpact');
    expect(crashResult.attempt.isSolarHourUnlocked).toBe(false);
    expect(crashResult.attempt.failureReasonEs).toBeTruthy();
  });

  it('should fail mission immediately with "Misión fallida – señal perdida" when exceeding 1.5 * initialAltitude (RN-05, FR-024)', () => {
    const moon = worldsById['moon'];
    const initial = useCase.createInitialState(moon);

    const result = useCase.step({
      world: moon,
      state: {
        ...initial.state,
        altitude: 749.5,
        verticalVelocity: 25.0,
        isThrusterActive: true,
      },
      attempt: initial.attempt,
      realDeltaSeconds: 0.02,
    });

    expect(result.state.status).toBe('lostSignal');
    expect(result.attempt.outcome).toBe('failedSignalLost');
    expect(result.attempt.failureReasonEs).toBe('Misión fallida – señal perdida');
    expect(result.attempt.isSolarHourUnlocked).toBe(false);
  });

  it('should preserve trajectory invariance under timeScale and keep horizontalVelocity === 0 (RN-07, FR-008, FR-025, FR-026)', () => {
    const moonScaled = worldsById['moon']; // timeScale = 4
    const moonRealTime: CelestialBody = { ...moonScaled, timeScale: 1 };

    const initScaled = useCase.createInitialState(moonScaled);
    const initReal = useCase.createInitialState(moonRealTime);

    const stepScaled = useCase.step({
      world: moonScaled,
      state: { ...initScaled.state, isThrusterActive: true },
      attempt: initScaled.attempt,
      realDeltaSeconds: 0.01,
    });

    const stepReal = useCase.step({
      world: moonRealTime,
      state: { ...initReal.state, isThrusterActive: true },
      attempt: initReal.attempt,
      realDeltaSeconds: 0.04,
    });

    expect(stepScaled.state.altitude).toBeCloseTo(stepReal.state.altitude, 6);
    expect(stepScaled.state.verticalVelocity).toBeCloseTo(stepReal.state.verticalVelocity, 6);
    expect(stepScaled.state.fuelPercentage).toBeCloseTo(stepReal.state.fuelPercentage, 6);
    expect(stepScaled.state.horizontalVelocity).toBe(0);
  });

  it('should allow landing on all 4 worlds with >= 15% remaining fuel using closed-loop guidance (SC-002)', () => {
    for (const world of Object.values(worldsById)) {
      let { state, attempt } = useCase.createInitialState(world);
      let steps = 0;

      while (attempt.outcome === 'inProgress' && steps < 5000) {
        const netBrakeAccel = Math.max(2.0, 24.0 - world.gravity);
        const stoppingDistance =
          Math.max(0, state.verticalVelocity * state.verticalVelocity - 1.2 * 1.2) /
          (2 * netBrakeAccel);

        let shouldThrust = false;
        if (state.altitude <= stoppingDistance + 18) {
          shouldThrust = state.verticalVelocity < -1.3;
        } else if (state.verticalVelocity < -28) {
          shouldThrust = true;
        }

        const next = useCase.step({
          world,
          state: { ...state, isThrusterActive: shouldThrust },
          attempt,
          realDeltaSeconds: 1 / 60,
        });
        state = next.state;
        attempt = next.attempt;
        steps++;
      }

      expect(attempt.outcome)
        .withContext(`World ${world.id} should land successfully`)
        .toBe('success');
      expect(attempt.remainingFuel)
        .withContext(`World ${world.id} should keep >= 15% fuel reserve`)
        .toBeGreaterThanOrEqual(15);
    }
  });
});
