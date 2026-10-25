import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:weinsolar_flutter/domain/models/celestial_body/celestial_body.dart';
import 'package:weinsolar_flutter/infrastructure/driven_adapters/celestial_body_local_adapter.dart';
import 'package:weinsolar_flutter/infrastructure/helpers/mappers/celestial_body_mapper.dart';

({int r, int g, int b}) _parseRgb(String hex) {
  final clean = hex.replaceFirst('#', '');
  final value = int.parse(clean, radix: 16);
  return (
    r: (value >> 16) & 0xFF,
    g: (value >> 8) & 0xFF,
    b: value & 0xFF,
  );
}

double _rgbDistance(String hexA, String hexB) {
  final a = _parseRgb(hexA);
  final b = _parseRgb(hexB);
  final dr = (a.r - b.r).toDouble();
  final dg = (a.g - b.g).toDouble();
  final db = (a.b - b.b).toDouble();
  return math.sqrt(dr * dr + dg * dg + db * db);
}

void main() {
  group('CelestialBodyMapper & CelestialBodyLocalAdapter (T019 — lightingProfile, RN-13, RN-14)', () {
    const weincodeVioletPalette = ['#18084D', '#5236FF', '#A599FF'];
    const forbiddenWeincodeColors = {'#18084D', '#5236FF', '#A599FF', '#FFFFFF'};

    Map<String, dynamic> buildValidRaw() {
      return <String, dynamic>{
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
          'scientificReference':
              'NASA Mars Science Laboratory Curiosity — PIA19400',
          'dayZenithHex': '#C67D50',
          'dayHorizonHex': '#E2A878',
          'sunsetZenithHex': '#6E473B',
          'sunsetHorizonHex': '#8C5B49',
          'nightZenithHex': '#1A110E',
          'nightHorizonHex': '#261914',
          'sunHaloHex': '#6C93B8',
        },
        'lightingProfile': <String, dynamic>{
          'sunAzimuthDeg': 250.0,
          'sunColorDayHex': '#FFE9D2',
          'sunColorSunsetHex': '#6C93B8',
          'ambientDayIntensity': 0.40,
          'twilightFadeDeg': 8.0,
          'shadowSoftness': 0.45,
          'scientificReference':
              'NASA Mars Science Laboratory Curiosity — PIA19400',
        },
      };
    }

    test('celestialBodyDataToEntity maps raw Map<String, dynamic> including lightingProfile', () {
      final raw = buildValidRaw();
      final entity = celestialBodyDataToEntity(raw);

      expect(entity.id, CelestialBodyId.mars);
      expect(entity.nameEs, 'Marte');
      expect(entity.gravity, 3.71);
      expect(entity.atmosphericDensity, 0.020);
      expect(entity.timeScale, 3.0);
      expect(entity.ceilingAltitude, 750.0);
      expect(entity.terrainTheme.featureType, 'red_regolith_rocks');
      expect(entity.scientificReference, contains('Curiosity'));
      expect(entity.lightingProfile.sunAzimuthDeg, 250.0);
      expect(entity.lightingProfile.sunColorDayHex, '#FFE9D2');
      expect(entity.lightingProfile.sunColorSunsetHex, '#6C93B8');
      expect(entity.lightingProfile.ambientDayIntensity, 0.40);
      expect(entity.lightingProfile.twilightFadeDeg, 8.0);
      expect(entity.lightingProfile.shadowSoftness, 0.45);
    });

    test('throws domain StateError when lightingProfile is missing', () {
      final raw = buildValidRaw()..remove('lightingProfile');
      expect(() => celestialBodyDataToEntity(raw), throwsStateError);
    });

    test('exposes lightingProfile on all 4 worlds with Moon ambientDayIntensity == 0 and twilightFadeDeg == 0 (RN-14)', () async {
      const adapter = CelestialBodyLocalAdapter();
      final worlds = await adapter.getAll();
      expect(worlds.length, 4);

      for (final world in worlds) {
        expect(world.lightingProfile.sunAzimuthDeg, 250.0);
        expect(
          world.lightingProfile.scientificReference,
          equals(world.skyOpticalProfile.scientificReference),
        );
      }

      final moon = await adapter.getById(CelestialBodyId.moon);
      expect(moon.lightingProfile.ambientDayIntensity, 0.0);
      expect(moon.lightingProfile.twilightFadeDeg, 0.0);
      expect(moon.lightingProfile.shadowSoftness, 0.0);
    });

    test('enforces RN-13 RGB distances on all colors of LightingProfile, SkyOpticalProfile, and TerrainTheme across all 4 worlds', () async {
      const adapter = CelestialBodyLocalAdapter();
      final worlds = await adapter.getAll();

      for (final world in worlds) {
        final colorsToCheck = <String, String>{
          '${world.id.name}.lighting.sunColorDayHex':
              world.lightingProfile.sunColorDayHex,
          '${world.id.name}.lighting.sunColorSunsetHex':
              world.lightingProfile.sunColorSunsetHex,
          '${world.id.name}.terrain.primarySurfaceHex':
              world.terrainTheme.primarySurfaceHex,
          '${world.id.name}.terrain.secondaryFeatureHex':
              world.terrainTheme.secondaryFeatureHex,
          '${world.id.name}.terrain.landingPadHex':
              world.terrainTheme.landingPadHex,
          '${world.id.name}.sky.dayZenithHex':
              world.skyOpticalProfile.dayZenithHex,
          '${world.id.name}.sky.dayHorizonHex':
              world.skyOpticalProfile.dayHorizonHex,
          '${world.id.name}.sky.sunsetZenithHex':
              world.skyOpticalProfile.sunsetZenithHex,
          '${world.id.name}.sky.sunsetHorizonHex':
              world.skyOpticalProfile.sunsetHorizonHex,
          '${world.id.name}.sky.nightZenithHex':
              world.skyOpticalProfile.nightZenithHex,
          '${world.id.name}.sky.nightHorizonHex':
              world.skyOpticalProfile.nightHorizonHex,
          '${world.id.name}.sky.sunHaloHex':
              world.skyOpticalProfile.sunHaloHex,
        };

        for (final entry in colorsToCheck.entries) {
          final label = entry.key;
          final hex = entry.value.toUpperCase();

          expect(
            forbiddenWeincodeColors.contains(hex),
            isFalse,
            reason: '$label ($hex) must not be a Weincode HUD color',
          );
          for (final forbidden in weincodeVioletPalette) {
            expect(
              _rgbDistance(hex, forbidden),
              greaterThanOrEqualTo(48.0),
              reason: '$label ($hex) distance to $forbidden',
            );
          }
          expect(
            _rgbDistance(hex, '#FFFFFF'),
            greaterThanOrEqualTo(16.0),
            reason: '$label ($hex) distance to #FFFFFF',
          );
        }
      }
    });
  });
}
