import 'package:flutter_test/flutter_test.dart';
import 'package:weinsolar_flutter/domain/models/celestial_body/celestial_body.dart';
import 'package:weinsolar_flutter/infrastructure/driven_adapters/celestial_body_local_adapter.dart';
import 'package:weinsolar_flutter/infrastructure/helpers/mappers/celestial_body_mapper.dart';

void main() {
  group('CelestialBodyMapper & CelestialBodyLocalAdapter (T020)', () {
    const forbiddenWeincodeColors = {'#18084D', '#5236FF', '#A599FF'};

    test('celestialBodyDataToEntity maps raw Map<String, dynamic> to CelestialBody entity', () {
      final raw = <String, dynamic>{
        'id': 'mars',
        'nameEs': 'Marte',
        'gravity': 3.71,
        'atmosphericDensity': 0.020,
        'timeScale': 3.0,
        'initialAltitude': 500.0,
        'ceilingAltitude': 750.0,
        'initialVelocity': -20.0,
        'initialFuel': 100.0,
        'terrainTheme': <String, dynamic>{
          'primarySurfaceHex': '#A84A2B',
          'secondaryFeatureHex': '#702E19',
          'landingPadHex': '#8C5843',
          'featureType': 'red_regolith_rocks',
        },
        'skyOpticalProfile': <String, dynamic>{
          'scientificReference': 'NASA Mars Science Laboratory Curiosity — PIA19400',
          'dayZenithHex': '#C67D50',
          'dayHorizonHex': '#E2A878',
          'sunsetZenithHex': '#6E473B',
          'sunsetHorizonHex': '#8C5B49',
          'nightZenithHex': '#1A110E',
          'nightHorizonHex': '#261914',
          'sunHaloHex': '#6C93B8',
        },
      };

      final entity = celestialBodyDataToEntity(raw);

      expect(entity.id, CelestialBodyId.mars);
      expect(entity.nameEs, 'Marte');
      expect(entity.gravity, 3.71);
      expect(entity.atmosphericDensity, 0.020);
      expect(entity.timeScale, 3.0);
      expect(entity.ceilingAltitude, 750.0);
      expect(entity.terrainTheme.featureType, 'red_regolith_rocks');
      expect(
        entity.scientificReference,
        contains('Curiosity'),
      );
    });

    test('CelestialBodyLocalAdapter provides all 4 worlds offline with zero Weincode colors in terrain or sky (RN-08)', () async {
      const adapter = CelestialBodyLocalAdapter();
      final worlds = await adapter.getAll();

      expect(worlds.length, 4);

      for (final world in worlds) {
        final byId = await adapter.getById(world.id);
        expect(byId.id, world.id);
        expect(byId.nameEs, world.nameEs);

        final colorsToCheck = [
          world.terrainTheme.primarySurfaceHex.toUpperCase(),
          world.terrainTheme.secondaryFeatureHex.toUpperCase(),
          world.terrainTheme.landingPadHex.toUpperCase(),
          world.skyOpticalProfile.dayZenithHex.toUpperCase(),
          world.skyOpticalProfile.dayHorizonHex.toUpperCase(),
          world.skyOpticalProfile.sunsetZenithHex.toUpperCase(),
          world.skyOpticalProfile.sunsetHorizonHex.toUpperCase(),
          world.skyOpticalProfile.nightZenithHex.toUpperCase(),
          world.skyOpticalProfile.nightHorizonHex.toUpperCase(),
          world.skyOpticalProfile.sunHaloHex.toUpperCase(),
        ];

        for (final hex in colorsToCheck) {
          expect(
            forbiddenWeincodeColors.contains(hex),
            isFalse,
            reason: 'World ${world.nameEs} must not contain Weincode HUD color $hex in 3D scene',
          );
        }
      }
    });
  });
}
