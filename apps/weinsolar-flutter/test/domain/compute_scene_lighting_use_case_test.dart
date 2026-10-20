import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:weinsolar_flutter/domain/models/celestial_body/celestial_body.dart';
import 'package:weinsolar_flutter/domain/usecase/compute_scene_lighting_use_case.dart';
import 'package:weinsolar_flutter/infrastructure/driven_adapters/celestial_body_local_adapter.dart';

({int r, int g, int b}) _parseRgb(String hex) {
  final clean = hex.replaceFirst('#', '');
  final value = int.parse(clean, radix: 16);
  return (
    r: (value >> 16) & 0xFF,
    g: (value >> 8) & 0xFF,
    b: value & 0xFF,
  );
}

double _euclideanDistance(String hexA, String hexB) {
  final a = _parseRgb(hexA);
  final b = _parseRgb(hexB);
  final dr = (a.r - b.r).toDouble();
  final dg = (a.g - b.g).toDouble();
  final db = (a.b - b.b).toDouble();
  return math.sqrt(dr * dr + dg * dg + db * db);
}

const _weincodeBrandPurples = ['#18084D', '#5236FF', '#A599FF'];

void main() {
  group(
    'ComputeSceneLightingUseCase (T016 & T069 — RN-12, RN-13, RN-14, RN-15, FR-016, FR-018)',
    () {
      const useCase = ComputeSceneLightingUseCase();
      late Map<CelestialBodyId, CelestialBody> worlds;

      setUpAll(() async {
        final list = await const CelestialBodyLocalAdapter().getAll();
        worlds = {for (final w in list) w.id: w};
      });

      test(
        'returns normalized sunDirection with y = sin(e) (tolerance 1e-9) for e in {65, 45, 10, 0, -10}',
        () {
          final earth = worlds[CelestialBodyId.earth]!;
          for (final elev in [65.0, 45.0, 10.0, 0.0, -10.0]) {
            final state = useCase.execute(earth, elev);
            final dir = state.sunDirection;
            final norm =
                math.sqrt(dir.x * dir.x + dir.y * dir.y + dir.z * dir.z);
            final expectedY = math.sin(elev * math.pi / 180.0);

            expect((norm - 1.0).abs(), lessThanOrEqualTo(1e-9),
                reason: 'norm at $elev°');
            expect((dir.y - expectedY).abs(), lessThanOrEqualTo(1e-9),
                reason: 'y at $elev°');
          }
        },
      );

      test(
        'sets castsShadows == (e > 0) and expectedShadowLengthRatio = 1/tan(e) monotonically increasing from 89° to 1° (RN-12)',
        () {
          final earth = worlds[CelestialBodyId.earth]!;

          final s45 = useCase.execute(earth, 45.0);
          expect(s45.castsShadows, isTrue);
          expect(s45.expectedShadowLengthRatio, closeTo(1.0, 1e-6));

          final s10 = useCase.execute(earth, 10.0);
          expect(s10.castsShadows, isTrue);
          expect(
            s10.expectedShadowLengthRatio,
            closeTo(1.0 / math.tan(10.0 * math.pi / 180.0), 1e-6),
          );

          var prevRatio = 0.0;
          for (var e = 89; e >= 1; e--) {
            final ratio =
                useCase.execute(earth, e.toDouble()).expectedShadowLengthRatio!;
            expect(ratio, greaterThan(prevRatio), reason: 'monotonic at $e°');
            prevRatio = ratio;
          }

          for (final nonPos in [0.0, -5.0, -10.0]) {
            final s = useCase.execute(earth, nonPos);
            expect(s.castsShadows, isFalse, reason: 'castsShadows at $nonPos°');
            expect(s.expectedShadowLengthRatio, isNull,
                reason: 'expectedShadowLengthRatio at $nonPos°');
          }
        },
      );

      test('clamps elevation to [-10, 90] and is strictly deterministic', () {
        final mars = worlds[CelestialBodyId.mars]!;

        final low = useCase.execute(mars, -45.0);
        expect(low.solarElevationDeg, -10.0);

        final high = useCase.execute(mars, 130.0);
        expect(high.solarElevationDeg, 90.0);

        final first = useCase.execute(mars, 18.5);
        final second = useCase.execute(mars, 18.5);
        expect(first, equals(second));
      });

      test('copies shadowSoftness from LightingProfile for each world (RN-15)',
          () {
        for (final world in worlds.values) {
          final state = useCase.execute(world, 65.0);
          expect(state.shadowSoftness, world.lightingProfile.shadowSoftness);
        }
      });

      test(
        'produces Mars cool blue-tinted sunset light at 2° and Earth warm orange sunset light at 2° (FR-016)',
        () {
          final marsState =
              useCase.execute(worlds[CelestialBodyId.mars]!, 2.0);
          expect(
            _euclideanDistance(marsState.sunColorHex, '#6C93B8'),
            lessThan(30.0),
          );

          final earthState =
              useCase.execute(worlds[CelestialBodyId.earth]!, 2.0);
          final rgb = _parseRgb(earthState.sunColorHex);
          expect(rgb.r, greaterThan(rgb.b + 100));
        },
      );

      test(
        'enforces Moon vacuum lighting (ambientIntensity == 0 and abrupt cutoff at 0°) and Titan diffuse twilight down to -10°',
        () {
          final moon = worlds[CelestialBodyId.moon]!;
          for (final elev in [-10.0, -1.0, -0.1, 0.0, 0.1, 10.0, 45.0, 90.0]) {
            final state = useCase.execute(moon, elev);
            expect(state.ambientIntensity, 0.0,
                reason: 'moon ambient at $elev°');
          }
          expect(useCase.execute(moon, 0.1).sunIntensity, greaterThan(0.0));
          expect(useCase.execute(moon, -0.1).sunIntensity, 0.0);

          final titan = worlds[CelestialBodyId.titan]!;
          expect(useCase.execute(titan, 45.0).shadowSoftness, 0.9);
          var prev = useCase.execute(titan, 20.0).sunIntensity;
          for (var e = 19; e >= -10; e--) {
            final curr = useCase.execute(titan, e.toDouble()).sunIntensity;
            expect(curr, lessThanOrEqualTo(prev),
                reason: 'Titan sunIntensity at $e°');
            prev = curr;
          }
          expect(useCase.execute(titan, -5.0).sunIntensity, greaterThan(0.0));
        },
      );

      test(
        'varies sunIntensity and color channels smoothly (delta <= 0.08 per 0.5° step) on Earth, Mars, and Titan (FR-018)',
        () {
          for (final id in [
            CelestialBodyId.earth,
            CelestialBodyId.mars,
            CelestialBodyId.titan,
          ]) {
            final world = worlds[id]!;
            for (var e = -10.0; e <= 89.5; e += 0.5) {
              final a = useCase.execute(world, e);
              final b = useCase.execute(world, e + 0.5);

              expect(
                (a.sunIntensity - b.sunIntensity).abs(),
                lessThanOrEqualTo(0.08),
                reason: '${id.name} sunIntensity delta at $e°',
              );

              final s1 = _parseRgb(a.sunColorHex);
              final s2 = _parseRgb(b.sunColorHex);
              expect((s1.r - s2.r).abs() / 255.0, lessThanOrEqualTo(0.08));
              expect((s1.g - s2.g).abs() / 255.0, lessThanOrEqualTo(0.08));
              expect((s1.b - s2.b).abs() / 255.0, lessThanOrEqualTo(0.08));

              final a1 = _parseRgb(a.ambientSkyColorHex);
              final a2 = _parseRgb(b.ambientSkyColorHex);
              expect((a1.r - a2.r).abs() / 255.0, lessThanOrEqualTo(0.08));
              expect((a1.g - a2.g).abs() / 255.0, lessThanOrEqualTo(0.08));
              expect((a1.b - a2.b).abs() / 255.0, lessThanOrEqualTo(0.08));
            }
          }
        },
      );

      test(
        'satisfies RN-13 chromatic separation across every 1° step from -10° to 90° for all worlds',
        () {
          for (final world in worlds.values) {
            for (var e = -10; e <= 90; e += 1) {
              final state = useCase.execute(world, e.toDouble());
              for (final color in [
                state.sunColorHex,
                state.ambientSkyColorHex,
              ]) {
                for (final purple in _weincodeBrandPurples) {
                  expect(
                    _euclideanDistance(color, purple),
                    greaterThanOrEqualTo(48.0),
                    reason:
                        '${world.id.name} at $e° ($color vs $purple)',
                  );
                }
                expect(
                  _euclideanDistance(color, '#FFFFFF'),
                  greaterThanOrEqualTo(16.0),
                  reason: '${world.id.name} at $e° ($color vs #FFFFFF)',
                );
              }
            }
          }
        },
      );
    },
  );
}
