import 'package:flutter_test/flutter_test.dart';
import 'package:weinsolar_flutter/domain/models/celestial_body/celestial_body.dart';
import 'package:weinsolar_flutter/domain/models/simulation/lander_state.dart';
import 'package:weinsolar_flutter/domain/models/simulation/mission_attempt.dart';
import 'package:weinsolar_flutter/domain/usecase/simulate_descent_step_use_case.dart';
import 'package:weinsolar_flutter/infrastructure/driven_adapters/celestial_body_local_adapter.dart';

void main() {
  group('SimulateDescentStepUseCase (T029 - RN-01..RN-05, RN-07, SC-002, CA-US1-1..8)', () {
    late SimulateDescentStepUseCase useCase;
    late Map<CelestialBodyId, CelestialBody> worlds;

    setUpAll(() async {
      useCase = const SimulateDescentStepUseCase();
      final list = await const CelestialBodyLocalAdapter().getAll();
      worlds = {for (final w in list) w.id: w};
    });

    test('CA-US1-1 & RN-01 & RN-02: free fall in Moon vacuum has zero atmospheric drag (FR-004, FR-005)', () {
      final moon = worlds[CelestialBodyId.moon]!;
      final initialState = LanderState.initial(moon);
      final initialAttempt = MissionAttempt.initial(moon);

      // Moon timeScale is 4.0, so realDeltaSeconds = 0.25 => simulatedDelta = 1.0 s
      final result = useCase.execute(
        world: moon,
        state: initialState,
        attempt: initialAttempt,
        realDeltaSeconds: 0.25,
      );

      // v(1s) = -15.0 - 1.62 * 1.0 = -16.62 m/s (exact, 0 drag)
      expect(result.state.verticalVelocity, closeTo(-16.62, 1e-6));
      expect(result.state.altitude, lessThan(initialState.altitude));
      expect(result.state.horizontalVelocity, 0.0);
      expect(result.attempt.outcome, MissionOutcome.inProgress);
    });

    test('CA-US1-8 & FR-005: quadratic atmospheric drag slows descent in Earth/Titan compared to Moon', () {
      final moon = worlds[CelestialBodyId.moon]!;
      final titan = worlds[CelestialBodyId.titan]!;

      // Compare same initial velocity (-25 m/s) over 1.0 simulated second
      final moonState = LanderState.initial(moon).copyWith(verticalVelocity: -25.0);
      final titanState = LanderState.initial(titan).copyWith(verticalVelocity: -25.0);

      final moonStep = useCase.execute(
        world: moon,
        state: moonState,
        attempt: MissionAttempt.initial(moon),
        realDeltaSeconds: 1.0 / moon.timeScale,
      );
      final titanStep = useCase.execute(
        world: titan,
        state: titanState,
        attempt: MissionAttempt.initial(titan),
        realDeltaSeconds: 1.0 / titan.timeScale,
      );

      // In Titan (rho = 5.3), upward drag k_d * rho * v^2 = 0.0008 * 5.3 * 625 = 2.65 m/s^2 > g_titan (1.352 m/s^2)!
      // So Titan actually decelerates a fast -25 m/s fall, whereas Moon accelerates it further negative.
      expect(titanStep.state.verticalVelocity, greaterThan(moonStep.state.verticalVelocity));
      expect(titanStep.state.verticalVelocity, greaterThan(-25.0));
      expect(moonStep.state.verticalVelocity, closeTo(-26.62, 1e-4));
    });

    test('CA-US1-2 & FR-006: active thruster decelerates fall and consumes fuel proportionally (3.5 %/s)', () {
      final mars = worlds[CelestialBodyId.mars]!;
      final state = LanderState.initial(mars).copyWith(
        fuelPercentage: 50.0,
        isThrusterActive: true,
      );

      // 0.1 s simulated time => realDeltaSeconds = 0.1 / mars.timeScale
      final result = useCase.execute(
        world: mars,
        state: state,
        attempt: MissionAttempt.initial(mars),
        realDeltaSeconds: 0.1 / mars.timeScale,
      );

      // Thruster provides +24.0 m/s^2 upward vs -3.71 m/s^2 gravity => speed magnitude decreases
      expect(result.state.verticalVelocity, greaterThan(state.verticalVelocity));
      expect(result.state.fuelPercentage, closeTo(50.0 - 3.5 * 0.1, 1e-5));
    });

    test('CA-US1-5 & RN-03 & FR-007: empty fuel tank cuts thrust and keeps fuel at 0.0', () {
      final earth = worlds[CelestialBodyId.earth]!;
      final emptyFuelState = LanderState.initial(earth).copyWith(
        fuelPercentage: 0.0,
        isThrusterActive: true,
      );
      final thrusterOffState = LanderState.initial(earth).copyWith(
        fuelPercentage: 0.0,
        isThrusterActive: false,
      );

      final resActiveNoFuel = useCase.execute(
        world: earth,
        state: emptyFuelState,
        attempt: MissionAttempt.initial(earth),
        realDeltaSeconds: 0.02,
      );
      final resOffNoFuel = useCase.execute(
        world: earth,
        state: thrusterOffState,
        attempt: MissionAttempt.initial(earth),
        realDeltaSeconds: 0.02,
      );

      expect(resActiveNoFuel.state.fuelPercentage, 0.0);
      expect(
        resActiveNoFuel.state.verticalVelocity,
        closeTo(resOffNoFuel.state.verticalVelocity, 1e-9),
      );
    });

    test('CA-US1-3, CA-US1-4, CA-US1-7 & RN-04: exact landing threshold boundary (-2.0 m/s success vs -2.1 m/s crash)', () {
      final mars = worlds[CelestialBodyId.mars]!;

      // Touchdown at -2.0 m/s (inclusive threshold) -> success & unlocks Solar Hour
      final safeContactState = LanderState.initial(mars).copyWith(
        altitude: 0.0,
        verticalVelocity: -2.0,
      );
      final safeResult = useCase.execute(
        world: mars,
        state: safeContactState,
        attempt: MissionAttempt.initial(mars),
        realDeltaSeconds: 0.016,
      );

      expect(safeResult.state.status, LanderStatus.landed);
      expect(safeResult.state.altitude, 0.0);
      expect(safeResult.attempt.outcome, MissionOutcome.success);
      expect(safeResult.attempt.isSolarHourUnlocked, isTrue);
      expect(safeResult.attempt.touchdownVelocity, closeTo(-2.0, 1e-6));
      expect(safeResult.attempt.failureReasonEs, isNull);

      // Touchdown at -2.1 m/s -> failedImpact & blocks Solar Hour (SC-004)
      final crashContactState = LanderState.initial(mars).copyWith(
        altitude: 0.0,
        verticalVelocity: -2.1,
      );
      final crashResult = useCase.execute(
        world: mars,
        state: crashContactState,
        attempt: MissionAttempt.initial(mars),
        realDeltaSeconds: 0.016,
      );

      expect(crashResult.state.status, LanderStatus.crashed);
      expect(crashResult.state.altitude, 0.0);
      expect(crashResult.attempt.outcome, MissionOutcome.failedImpact);
      expect(crashResult.attempt.isSolarHourUnlocked, isFalse);
      expect(crashResult.attempt.touchdownVelocity, closeTo(-2.1, 1e-6));
      expect(crashResult.attempt.failureReasonEs, isNotNull);
    });

    test('CA-US1-6 & RN-05 & FR-024: exceeding ceiling altitude (1.5 * initialAltitude = 750m) triggers failedSignalLost', () {
      final moon = worlds[CelestialBodyId.moon]!;
      final highState = LanderState.initial(moon).copyWith(
        altitude: 749.5,
        verticalVelocity: 20.0,
        isThrusterActive: true,
      );

      final result = useCase.execute(
        world: moon,
        state: highState,
        attempt: MissionAttempt.initial(moon),
        realDeltaSeconds: 0.05,
      );

      expect(result.state.status, LanderStatus.lostSignal);
      expect(result.attempt.outcome, MissionOutcome.failedSignalLost);
      expect(result.attempt.failureReasonEs, 'Misión fallida – señal perdida');
      expect(result.attempt.isSolarHourUnlocked, isFalse);
    });

    test('RN-07, FR-008, FR-025, FR-026: timeScale invariance and zero horizontal velocity', () {
      final moonWithScale4 = worlds[CelestialBodyId.moon]!;
      final moonWithScale1 = CelestialBody(
        id: moonWithScale4.id,
        nameEs: moonWithScale4.nameEs,
        gravity: moonWithScale4.gravity,
        atmosphericDensity: moonWithScale4.atmosphericDensity,
        timeScale: 1.0,
        initialAltitude: moonWithScale4.initialAltitude,
        ceilingAltitude: moonWithScale4.ceilingAltitude,
        initialVelocity: moonWithScale4.initialVelocity,
        initialFuel: moonWithScale4.initialFuel,
        terrainTheme: moonWithScale4.terrainTheme,
        skyOpticalProfile: moonWithScale4.skyOpticalProfile,
        lightingProfile: moonWithScale4.lightingProfile,
      );

      final resScaled = useCase.execute(
        world: moonWithScale4,
        state: LanderState.initial(moonWithScale4).copyWith(isThrusterActive: true),
        attempt: MissionAttempt.initial(moonWithScale4),
        realDeltaSeconds: 0.01, // simulatedDelta = 0.04s
      );

      final resRealtime = useCase.execute(
        world: moonWithScale1,
        state: LanderState.initial(moonWithScale1).copyWith(isThrusterActive: true),
        attempt: MissionAttempt.initial(moonWithScale1),
        realDeltaSeconds: 0.04, // simulatedDelta = 0.04s
      );

      expect(resScaled.state.altitude, closeTo(resRealtime.state.altitude, 1e-9));
      expect(
        resScaled.state.verticalVelocity,
        closeTo(resRealtime.state.verticalVelocity, 1e-9),
      );
      expect(
        resScaled.state.fuelPercentage,
        closeTo(resRealtime.state.fuelPercentage, 1e-9),
      );
      expect(resScaled.state.horizontalVelocity, 0.0);
    });

    test('SC-002: optimal piloting achieves safe landing (<= 2.0 m/s) with >= 15% remaining fuel on all 4 worlds', () {
      for (final world in worlds.values) {
        var state = LanderState.initial(world);
        var attempt = MissionAttempt.initial(world);

        // Simple closed-loop braking controller:
        // Estimate stopping distance d_stop = v^2 / (2 * (a_thrust - g))
        final netUpwardAccel = SimulateDescentStepUseCase.maxThrustAcceleration - world.gravity;

        var steps = 0;
        while (attempt.outcome == MissionOutcome.inProgress && steps < 10000) {
          final speedDown = -state.verticalVelocity;
          final stoppingDistance = speedDown > 1.5
              ? (speedDown * speedDown - 1.5 * 1.5) / (2.0 * netUpwardAccel)
              : 0.0;

          final shouldBurn = state.altitude <= stoppingDistance + 8.0 &&
              state.verticalVelocity < -1.5;

          state = state.copyWith(isThrusterActive: shouldBurn);

          final stepResult = useCase.execute(
            world: world,
            state: state,
            attempt: attempt,
            realDeltaSeconds: 0.01,
          );
          state = stepResult.state;
          attempt = stepResult.attempt;
          steps++;
        }

        expect(
          attempt.outcome,
          MissionOutcome.success,
          reason: 'Expected successful landing on ${world.nameEs}, got ${attempt.outcome} at v=${attempt.touchdownVelocity}',
        );
        expect(
          attempt.remainingFuel,
          greaterThanOrEqualTo(15.0),
          reason: 'Expected >= 15% fuel reserve on ${world.nameEs}, got ${attempt.remainingFuel}%',
        );
        expect(attempt.isSolarHourUnlocked, isTrue);
      }
    });
  });
}
