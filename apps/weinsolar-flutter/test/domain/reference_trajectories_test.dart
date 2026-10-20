import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:weinsolar_flutter/domain/models/celestial_body/celestial_body.dart';
import 'package:weinsolar_flutter/domain/models/simulation/lander_state.dart';
import 'package:weinsolar_flutter/domain/models/simulation/mission_attempt.dart';
import 'package:weinsolar_flutter/domain/usecase/get_celestial_bodies_use_case.dart';
import 'package:weinsolar_flutter/domain/usecase/simulate_descent_step_use_case.dart';
import 'package:weinsolar_flutter/infrastructure/driven_adapters/celestial_body_local_adapter.dart';

typedef ThrustProfileFn = bool Function(
  int tick,
  CelestialBody world,
  LanderState state,
  SimulateDescentStepUseCase useCase,
);

bool _impactTargetThruster(CelestialBody world, LanderState state) {
  if (state.status != LanderStatus.descending || state.fuelPercentage <= 0.0) {
    return false;
  }
  final netUpwardAccel =
      SimulateDescentStepUseCase.maxThrustAcceleration - world.gravity;
  final speedDown = -state.verticalVelocity;
  const targetImpactSpeed = 2.4;
  final stoppingDistance = speedDown > targetImpactSpeed
      ? (speedDown * speedDown - targetImpactSpeed * targetImpactSpeed) /
          (2.0 * netUpwardAccel)
      : 0.0;

  if (state.altitude <= stoppingDistance + 4.0) {
    return state.verticalVelocity < -targetImpactSpeed;
  }
  return state.verticalVelocity < -28.0;
}

void main() {
  const bool writeFixtures = bool.fromEnvironment(
    'WRITE_FIXTURES',
    defaultValue: false,
  );
  const double fixedDt = 1.0 / 60.0;
  const int maxTicks = 4000;
  const int sampleInterval = 30;
  const double tolerance = 1e-9;

  final Map<String, ThrustProfileFn> profiles = {
    'a_free_fall': (tick, world, state, useCase) => false,
    'b_continuous_ceiling_escape': (tick, world, state, useCase) => true,
    'c_safe_touchdown_le_2_0': (tick, world, state, useCase) =>
        useCase.computeAutopilotThruster(world: world, state: state),
    'd_impact_touchdown_gt_2_0': (tick, world, state, useCase) =>
        _impactTargetThruster(world, state),
    'e_alternating_pulses_0_5s': (tick, world, state, useCase) =>
        ((tick ~/ 30) % 2) == 0,
  };

  test(
    'Reference trajectories v1 (5 thrust profiles x 4 worlds, sampled every 30 ticks, tolerance 1e-9)',
    () async {
      const adapter = CelestialBodyLocalAdapter();
      const getBodies = GetCelestialBodiesUseCase(gateway: adapter);
      const useCase = SimulateDescentStepUseCase();
      final worlds = await getBodies.execute();

      final Map<String, dynamic> computedTrajectories = {};

      for (final world in worlds) {
        final worldKey = world.id.name;
        for (final entry in profiles.entries) {
          final profileName = entry.key;
          final profileFn = entry.value;
          final trajectoryKey = '${worldKey}__$profileName';

          var state = LanderState.initial(world);
          var attempt = MissionAttempt.initial(world);
          final List<Map<String, dynamic>> samples = [];

          for (var tick = 0;
              tick < maxTicks && state.status == LanderStatus.descending;
              tick++) {
            final thrusterActive = profileFn(tick, world, state, useCase);
            state = state.copyWith(isThrusterActive: thrusterActive);

            final stepResult = useCase.execute(
              world: world,
              state: state,
              attempt: attempt,
              realDeltaSeconds: fixedDt,
            );
            state = stepResult.state;
            attempt = stepResult.attempt;

            if (tick % sampleInterval == 0 ||
                state.status != LanderStatus.descending) {
              samples.add({
                'tick': tick,
                'altitude': state.altitude,
                'verticalVelocity': state.verticalVelocity,
                'horizontalVelocity': state.horizontalVelocity,
                'fuelPercentage': state.fuelPercentage,
                'isThrusterActive': state.isThrusterActive,
                'status': state.status.name,
              });
            }
          }

          computedTrajectories[trajectoryKey] = {
            'worldId': worldKey,
            'profile': profileName,
            'finalAttempt': {
              'worldId': attempt.worldId.name,
              'outcome': attempt.outcome.name,
              'touchdownVelocity': attempt.touchdownVelocity,
              'remainingFuel': attempt.remainingFuel,
              'isSolarHourUnlocked': attempt.isSolarHourUnlocked,
              'failureReasonEs': attempt.failureReasonEs,
            },
            'samples': samples,
          };
        }
      }

      final fixtureFile = File('test/fixtures/reference_trajectories.json');

      if (writeFixtures) {
        fixtureFile.parent.createSync(recursive: true);
        const encoder = JsonEncoder.withIndent('  ');
        fixtureFile.writeAsStringSync(
          '${encoder.convert(computedTrajectories)}\n',
        );
      }

      expect(
        fixtureFile.existsSync(),
        isTrue,
        reason:
            'Fixture test/fixtures/reference_trajectories.json must exist. Run with --dart-define=WRITE_FIXTURES=true first.',
      );

      final expectedData = jsonDecode(fixtureFile.readAsStringSync())
          as Map<String, dynamic>;

      expect(computedTrajectories.keys, equals(expectedData.keys));

      for (final key in expectedData.keys) {
        final expectedTrajectory = expectedData[key] as Map<String, dynamic>;
        final actualTrajectory =
            computedTrajectories[key] as Map<String, dynamic>;

        final expectedAttempt =
            expectedTrajectory['finalAttempt'] as Map<String, dynamic>;
        final actualAttempt =
            actualTrajectory['finalAttempt'] as Map<String, dynamic>;

        expect(
          actualAttempt['outcome'],
          equals(expectedAttempt['outcome']),
          reason: 'Mismatch in finalAttempt.outcome for $key',
        );
        expect(
          actualAttempt['isSolarHourUnlocked'],
          equals(expectedAttempt['isSolarHourUnlocked']),
          reason: 'Mismatch in finalAttempt.isSolarHourUnlocked for $key',
        );

        final expectedTouchdown =
            (expectedAttempt['touchdownVelocity'] as num?)?.toDouble();
        final actualTouchdown =
            (actualAttempt['touchdownVelocity'] as num?)?.toDouble();
        if (expectedTouchdown == null) {
          expect(actualTouchdown, isNull, reason: 'touchdownVelocity for $key');
        } else {
          expect(
            actualTouchdown,
            closeTo(expectedTouchdown, tolerance),
            reason: 'touchdownVelocity for $key',
          );
        }

        expect(
          (actualAttempt['remainingFuel'] as num).toDouble(),
          closeTo(
            (expectedAttempt['remainingFuel'] as num).toDouble(),
            tolerance,
          ),
          reason: 'remainingFuel for $key',
        );

        final expectedSamples = expectedTrajectory['samples'] as List<dynamic>;
        final actualSamples = actualTrajectory['samples'] as List<dynamic>;
        expect(
          actualSamples.length,
          equals(expectedSamples.length),
          reason: 'Sample count mismatch for $key',
        );

        for (var i = 0; i < expectedSamples.length; i++) {
          final expSample = expectedSamples[i] as Map<String, dynamic>;
          final actSample = actualSamples[i] as Map<String, dynamic>;

          expect(
            actSample['tick'],
            equals(expSample['tick']),
            reason: 'Tick index mismatch at $key sample $i',
          );
          expect(
            (actSample['altitude'] as num).toDouble(),
            closeTo((expSample['altitude'] as num).toDouble(), tolerance),
            reason: 'Altitude mismatch at $key sample $i',
          );
          expect(
            (actSample['verticalVelocity'] as num).toDouble(),
            closeTo(
              (expSample['verticalVelocity'] as num).toDouble(),
              tolerance,
            ),
            reason: 'Velocity mismatch at $key sample $i',
          );
          expect(
            (actSample['fuelPercentage'] as num).toDouble(),
            closeTo((expSample['fuelPercentage'] as num).toDouble(), tolerance),
            reason: 'Fuel mismatch at $key sample $i',
          );
          expect(
            actSample['status'],
            equals(expSample['status']),
            reason: 'Status mismatch at $key sample $i',
          );
        }
      }
    },
  );
}
