import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:weinsolar_flutter/domain/models/celestial_body/celestial_body.dart';
import 'package:weinsolar_flutter/domain/models/scene/terrain_layout.dart';
import 'package:weinsolar_flutter/domain/models/scene/visual_quality.dart';
import 'package:weinsolar_flutter/domain/usecase/generate_terrain_layout_use_case.dart';
import 'package:weinsolar_flutter/infrastructure/driven_adapters/celestial_body_local_adapter.dart';

void main() {
  group('GenerateTerrainLayoutUseCase (T038 — RN-10, RN-15, US1)', () {
    late GenerateTerrainLayoutUseCase useCase;
    late Map<CelestialBodyId, CelestialBody> worlds;

    setUpAll(() async {
      final list = await const CelestialBodyLocalAdapter().getAll();
      worlds = {for (final w in list) w.id: w};
    });

    setUp(() {
      useCase = GenerateTerrainLayoutUseCase();
    });

    test(
      'generates deterministic layouts with resolution 192 (high) and 64 (basic) and heights.length == resolution^2',
      () {
        for (final world in worlds.values) {
          for (final quality in VisualQuality.values) {
            final expectedRes = quality == VisualQuality.high ? 192 : 64;
            final first = useCase.execute(world, quality);
            final second = useCase.execute(world, quality);

            expect(first.sizeMeters, 600.0);
            expect(first.padRadiusMeters, 6.0);
            expect(first.resolution, expectedRes);
            expect(first.heights.length, expectedRes * expectedRes);
            expect(first.heights, equals(second.heights));
            expect(first.features.length, equals(second.features.length));
          }
        }
      },
    );

    test(
      'enforces RN-10: exact height == 0 on vertices within padRadiusMeters (6.0 m) and no TerrainFeature within padRadius + 2 m',
      () {
        for (final world in worlds.values) {
          for (final quality in VisualQuality.values) {
            final layout = useCase.execute(world, quality);
            final res = layout.resolution;
            final half = layout.sizeMeters / 2.0;

            for (var row = 0; row < res; row++) {
              final z = -half + (row / (res - 1)) * layout.sizeMeters;
              for (var col = 0; col < res; col++) {
                final x = -half + (col / (res - 1)) * layout.sizeMeters;
                final dist = math.sqrt(x * x + z * z);
                if (dist <= layout.padRadiusMeters) {
                  expect(
                    layout.heights[row * res + col],
                    0.0,
                    reason:
                        '${world.id.name} ($quality) vertex ($x, $z) must have height 0',
                  );
                }
              }
            }

            for (final feat in layout.features) {
              final dist = math.sqrt(feat.x * feat.x + feat.z * feat.z);
              expect(
                dist,
                greaterThanOrEqualTo(layout.padRadiusMeters + 2.0),
                reason:
                    '${world.id.name} ($quality) feature at (${feat.x}, ${feat.z}) too close to pad',
              );
            }
          }
        }
      },
    );

    test(
      'produces world-characteristic terrain features and keeps basic feature count within 40% of high (+-1) (RN-15)',
      () {
        final earthHigh =
            useCase.execute(worlds[CelestialBodyId.earth]!, VisualQuality.high);
        expect(
          earthHigh.features.any((f) => f.kind == TerrainFeatureKind.rock),
          isTrue,
        );
        expect(
          earthHigh.features
              .any((f) => f.kind == TerrainFeatureKind.vegetation),
          isTrue,
        );

        final marsHigh =
            useCase.execute(worlds[CelestialBodyId.mars]!, VisualQuality.high);
        expect(
          marsHigh.features.any((f) => f.kind == TerrainFeatureKind.rock),
          isTrue,
        );
        expect(
          marsHigh.features.any((f) => f.kind == TerrainFeatureKind.dune),
          isTrue,
        );

        final moonHigh =
            useCase.execute(worlds[CelestialBodyId.moon]!, VisualQuality.high);
        expect(
          moonHigh.features.any((f) => f.kind == TerrainFeatureKind.crater),
          isTrue,
        );

        final titanHigh =
            useCase.execute(worlds[CelestialBodyId.titan]!, VisualQuality.high);
        expect(
          titanHigh.features.any((f) => f.kind == TerrainFeatureKind.iceRidge),
          isTrue,
        );

        for (final world in worlds.values) {
          final highCount =
              useCase.execute(world, VisualQuality.high).features.length;
          final basicCount =
              useCase.execute(world, VisualQuality.basic).features.length;
          final expectedBasic = (highCount * 0.4).round();
          expect(
            (basicCount - expectedBasic).abs(),
            lessThanOrEqualTo(1),
            reason:
                '${world.id.name} basic=$basicCount vs 40% of high=$highCount',
          );
        }
      },
    );
  });
}
