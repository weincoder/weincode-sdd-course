import 'package:flutter_test/flutter_test.dart';
import 'package:weinsolar_flutter/domain/models/celestial_body/celestial_body.dart';
import 'package:weinsolar_flutter/domain/models/simulation/mission_attempt.dart';
import 'package:weinsolar_flutter/domain/usecase/evaluate_solar_hour_use_case.dart';
import 'package:weinsolar_flutter/infrastructure/driven_adapters/celestial_body_local_adapter.dart';

({int r, int g, int b}) _parseHex(String hex) {
  final clean = hex.replaceFirst('#', '');
  final value = int.parse(clean, radix: 16);
  return (
    r: (value >> 16) & 0xFF,
    g: (value >> 8) & 0xFF,
    b: value & 0xFF,
  );
}

void main() {
  group('EvaluateSolarHourUseCase (T042 - RN-06, RN-08, FR-012, FR-015, FR-030, CA-US2-1..6)', () {
    late EvaluateSolarHourUseCase useCase;
    late Map<CelestialBodyId, CelestialBody> worlds;

    setUpAll(() async {
      useCase = const EvaluateSolarHourUseCase();
      final list = await const CelestialBodyLocalAdapter().getAll();
      worlds = {for (final w in list) w.id: w};
    });

    MissionAttempt successfulAttempt(CelestialBody world) {
      return MissionAttempt(
        worldId: world.id,
        outcome: MissionOutcome.success,
        touchdownVelocity: -1.4,
        remainingFuel: 45.0,
        isSolarHourUnlocked: true,
      );
    }

    test('CA-US2-6 & RN-06 & FR-012 & SC-004: strictly blocks Solar Hour if outcome is not success', () {
      final mars = worlds[CelestialBodyId.mars]!;

      for (final outcome in [
        MissionOutcome.inProgress,
        MissionOutcome.failedImpact,
        MissionOutcome.failedSignalLost,
        MissionOutcome.abandoned,
      ]) {
        final attempt = MissionAttempt(
          worldId: mars.id,
          outcome: outcome,
          touchdownVelocity: -6.5,
          remainingFuel: 20.0,
          isSolarHourUnlocked: false,
          failureReasonEs: 'Fallo',
        );

        final state = useCase.execute(
          world: mars,
          attempt: attempt,
          solarElevationDeg: 10.0,
          cameraAzimuthDeg: 120.0,
        );

        expect(state.isUnlocked, isFalse, reason: 'Outcome $outcome must lock Solar Hour');
        expect(state.directLightIntensity, 0.0);
      }
    });

    test('CA-US2-1 & CA-US2-2: Earth transitions from daytime blue (65°) to Rayleigh orange/red sunset (5°)', () {
      final earth = worlds[CelestialBodyId.earth]!;
      final attempt = successfulAttempt(earth);

      final highSun = useCase.execute(
        world: earth,
        attempt: attempt,
        solarElevationDeg: 65.0,
        cameraAzimuthDeg: 0.0,
      );
      final sunset = useCase.execute(
        world: earth,
        attempt: attempt,
        solarElevationDeg: 5.0,
        cameraAzimuthDeg: 45.0,
      );

      expect(highSun.isUnlocked, isTrue);
      final dayHorizonRgb = _parseHex(highSun.horizonColorHex);
      final sunsetHorizonRgb = _parseHex(sunset.horizonColorHex);

      // Daytime horizon is blue-dominant (B > R)
      expect(dayHorizonRgb.b, greaterThan(dayHorizonRgb.r));
      // Sunset horizon is Rayleigh orange/red-dominant (R > B and R > G)
      expect(sunsetHorizonRgb.r, greaterThan(sunsetHorizonRgb.b));
      expect(sunsetHorizonRgb.r, greaterThan(sunsetHorizonRgb.g));
      expect(sunset.cameraAzimuthDeg, 45.0);
    });

    test('CA-US2-3: Mars ochre sky exhibits a cold blue circumsolar halo near sunset (B > R)', () {
      final mars = worlds[CelestialBodyId.mars]!;
      final attempt = successfulAttempt(mars);

      final marsSunset = useCase.execute(
        world: mars,
        attempt: attempt,
        solarElevationDeg: 8.0,
        cameraAzimuthDeg: 180.0,
      );

      final horizonRgb = _parseHex(marsSunset.horizonColorHex);
      final haloRgb = _parseHex(marsSunset.sunHaloColorHex);

      // Ochre/reddish outer sky (R > B)
      expect(horizonRgb.r, greaterThan(horizonRgb.b));
      // Cold blue circumsolar halo (B > R) per Curiosity PIA19400
      expect(haloRgb.b, greaterThan(haloRgb.r));
    });

    test('CA-US2-4 & FR-030: Moon keeps permanent black sky (#000000), 0 ambient light, 1.0 shadow hardness, and abrupt cutoff < 0°', () {
      final moon = worlds[CelestialBodyId.moon]!;
      final attempt = successfulAttempt(moon);

      for (final elevation in [65.0, 10.0, 0.5, -5.0]) {
        final state = useCase.execute(
          world: moon,
          attempt: attempt,
          solarElevationDeg: elevation,
          cameraAzimuthDeg: 90.0,
        );

        expect(state.zenithColorHex, '#000000');
        expect(state.horizonColorHex, '#000000');
        expect(state.ambientLightIntensity, 0.0);
        expect(state.shadowHardness, 1.0);

        if (elevation >= 0.0) {
          expect(state.directLightIntensity, 1.0);
        } else {
          // Abrupt light cutoff below horizon
          expect(state.directLightIntensity, 0.0);
        }
      }
    });

    test('CA-US2-5 & FR-030: Titan displays dense amber haze with diffuse shadows (shadowHardness <= 0.2) and gradual darkening', () {
      final titan = worlds[CelestialBodyId.titan]!;
      final attempt = successfulAttempt(titan);

      final dayTitan = useCase.execute(
        world: titan,
        attempt: attempt,
        solarElevationDeg: 60.0,
        cameraAzimuthDeg: 0.0,
      );
      final duskTitan = useCase.execute(
        world: titan,
        attempt: attempt,
        solarElevationDeg: 5.0,
        cameraAzimuthDeg: 0.0,
      );
      final nightTitan = useCase.execute(
        world: titan,
        attempt: attempt,
        solarElevationDeg: -8.0,
        cameraAzimuthDeg: 0.0,
      );

      expect(dayTitan.shadowHardness, lessThanOrEqualTo(0.2));
      expect(duskTitan.shadowHardness, lessThanOrEqualTo(0.2));

      final dayRgb = _parseHex(dayTitan.horizonColorHex);
      final duskRgb = _parseHex(duskTitan.horizonColorHex);
      final nightRgb = _parseHex(nightTitan.horizonColorHex);

      // Amber haze has R > G > B
      expect(dayRgb.r, greaterThan(dayRgb.g));
      expect(dayRgb.g, greaterThan(dayRgb.b));

      // Gradual darkening as sun lowers
      final dayLuma = dayRgb.r + dayRgb.g + dayRgb.b;
      final duskLuma = duskRgb.r + duskRgb.g + duskRgb.b;
      final nightLuma = nightRgb.r + nightRgb.g + nightRgb.b;

      expect(dayLuma, greaterThan(duskLuma));
      expect(duskLuma, greaterThan(nightLuma));
    });

    test('CA-US4-3 & RN-08 & FR-021: no optical sky or halo color ever matches Weincode HUD colors (#18084D, #5236FF, #A599FF)', () {
      const forbiddenWeincodeColors = {'#18084D', '#5236FF', '#A599FF'};

      for (final world in worlds.values) {
        final attempt = successfulAttempt(world);
        for (var elev = -10.0; elev <= 90.0; elev += 5.0) {
          final state = useCase.execute(
            world: world,
            attempt: attempt,
            solarElevationDeg: elev,
            cameraAzimuthDeg: 0.0,
          );

          expect(
            forbiddenWeincodeColors.contains(state.zenithColorHex.toUpperCase()),
            isFalse,
            reason: '${world.nameEs} zenith at $elev° matched Weincode color ${state.zenithColorHex}',
          );
          expect(
            forbiddenWeincodeColors.contains(state.horizonColorHex.toUpperCase()),
            isFalse,
            reason: '${world.nameEs} horizon at $elev° matched Weincode color ${state.horizonColorHex}',
          );
          expect(
            forbiddenWeincodeColors.contains(state.sunHaloColorHex.toUpperCase()),
            isFalse,
            reason: '${world.nameEs} halo at $elev° matched Weincode color ${state.sunHaloColorHex}',
          );
        }
      }
    });
  });
}
