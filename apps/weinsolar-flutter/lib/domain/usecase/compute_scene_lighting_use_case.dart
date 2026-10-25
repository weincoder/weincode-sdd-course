import 'dart:math' as math;

import '../models/celestial_body/celestial_body.dart';
import '../models/scene/scene_lighting_state.dart';
import '../models/simulation/solar_hour_state.dart';

class ComputeSceneLightingUseCase {
  const ComputeSceneLightingUseCase();

  SceneLightingState execute(CelestialBody world, double solarElevationDeg) {
    final clampedElevation = solarElevationDeg.clamp(
      SolarHourState.minElevationDeg,
      SolarHourState.maxElevationDeg,
    );
    final profile = world.lightingProfile;

    final eRad = clampedElevation * math.pi / 180.0;
    final aRad = profile.sunAzimuthDeg * math.pi / 180.0;
    final cosE = math.cos(eRad);
    final sinE = math.sin(eRad);

    final sunDirection = Vector3Value(
      x: cosE * math.sin(aRad),
      y: sinE,
      z: cosE * math.cos(aRad),
    );

    final dayBlend = _smoothstep(0.0, 20.0, clampedElevation);
    final sunColorHex = _lerpHex(
      profile.sunColorSunsetHex,
      profile.sunColorDayHex,
      dayBlend,
    );

    final double sunIntensity;
    final double ambientIntensity;

    if (profile.twilightFadeDeg <= 0.0) {
      sunIntensity = clampedElevation > 0.0 ? 1.0 : 0.0;
      ambientIntensity = 0.0;
    } else if (clampedElevation >= 0.0) {
      sunIntensity = 0.35 + 0.65 * _smoothstep(0.0, 18.0, clampedElevation);
      final ambRamp = 0.45 + 0.55 * _smoothstep(0.0, 25.0, clampedElevation);
      ambientIntensity = profile.ambientDayIntensity * ambRamp;
    } else {
      final twilightFactor =
          _smoothstep(-profile.twilightFadeDeg, 0.0, clampedElevation);
      sunIntensity = 0.35 * twilightFactor;
      ambientIntensity = profile.ambientDayIntensity * 0.45 * twilightFactor;
    }

    final ambientSkyColorHex = _interpolateZenithHex(
      world.skyOpticalProfile,
      clampedElevation,
    );
    final ambientGroundColorHex = world.terrainTheme.primarySurfaceHex;
    final castsShadows = clampedElevation > 0.0;
    final expectedShadowLengthRatio =
        castsShadows ? (1.0 / math.tan(eRad)) : null;

    return SceneLightingState(
      solarElevationDeg: clampedElevation,
      sunDirection: sunDirection,
      sunColorHex: sunColorHex,
      sunIntensity: sunIntensity,
      ambientSkyColorHex: ambientSkyColorHex,
      ambientGroundColorHex: ambientGroundColorHex,
      ambientIntensity: ambientIntensity,
      shadowSoftness: profile.shadowSoftness,
      castsShadows: castsShadows,
      expectedShadowLengthRatio: expectedShadowLengthRatio,
    );
  }

  static double _smoothstep(double edge0, double edge1, double x) {
    if (edge0 == edge1) {
      return x >= edge1 ? 1.0 : 0.0;
    }
    final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
  }

  static String _interpolateZenithHex(
    SkyOpticalProfile optical,
    double elevationDeg,
  ) {
    if (elevationDeg >= 0.0) {
      final t = _smoothstep(0.0, 65.0, elevationDeg);
      return _lerpHex(optical.sunsetZenithHex, optical.dayZenithHex, t);
    } else {
      final t = _smoothstep(-10.0, 0.0, elevationDeg);
      return _lerpHex(optical.nightZenithHex, optical.sunsetZenithHex, t);
    }
  }

  static ({int r, int g, int b}) _parseRgb(String hex) {
    final clean = hex.replaceFirst('#', '');
    final value = int.parse(clean, radix: 16);
    return (
      r: (value >> 16) & 0xFF,
      g: (value >> 8) & 0xFF,
      b: value & 0xFF,
    );
  }

  static String _lerpHex(String hexA, String hexB, double t) {
    final a = _parseRgb(hexA);
    final b = _parseRgb(hexB);
    final f = t.clamp(0.0, 1.0);
    final r = (a.r + (b.r - a.r) * f).round().clamp(0, 255);
    final g = (a.g + (b.g - a.g) * f).round().clamp(0, 255);
    final bl = (a.b + (b.b - a.b) * f).round().clamp(0, 255);
    String byteHex(int v) => v.toRadixString(16).padLeft(2, '0').toUpperCase();
    return '#${byteHex(r)}${byteHex(g)}${byteHex(bl)}';
  }
}
