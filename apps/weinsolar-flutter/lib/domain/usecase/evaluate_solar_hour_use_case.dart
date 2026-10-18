import '../models/celestial_body/celestial_body.dart';
import '../models/simulation/mission_attempt.dart';
import '../models/simulation/solar_hour_state.dart';

class EvaluateSolarHourUseCase {
  static const Set<String> _forbiddenWeincodeColors = {
    '#18084D',
    '#5236FF',
    '#A599FF',
  };

  const EvaluateSolarHourUseCase();

  SolarHourState execute({
    required CelestialBody world,
    required MissionAttempt attempt,
    double solarElevationDeg = SolarHourState.defaultInitialElevationDeg,
    double cameraAzimuthDeg = 0.0,
  }) {
    if (attempt.outcome != MissionOutcome.success ||
        !attempt.isSolarHourUnlocked) {
      return SolarHourState.locked();
    }

    final clampedElevation = solarElevationDeg.clamp(
      SolarHourState.minElevationDeg,
      SolarHourState.maxElevationDeg,
    );
    var normalizedAzimuth = cameraAzimuthDeg % 360.0;
    if (normalizedAzimuth < 0.0) {
      normalizedAzimuth += 360.0;
    }

    return switch (world.id) {
      CelestialBodyId.earth =>
        _evaluateEarth(world, clampedElevation, normalizedAzimuth),
      CelestialBodyId.mars =>
        _evaluateMars(world, clampedElevation, normalizedAzimuth),
      CelestialBodyId.moon =>
        _evaluateMoon(world, clampedElevation, normalizedAzimuth),
      CelestialBodyId.titan =>
        _evaluateTitan(world, clampedElevation, normalizedAzimuth),
    };
  }

  SolarHourState _evaluateEarth(
    CelestialBody world,
    double elev,
    double azimuth,
  ) {
    final profile = world.skyOpticalProfile;
    String zenith;
    String horizon;
    String halo;
    double ambient;
    double direct;

    if (elev >= 30.0) {
      final t = ((elev - 30.0) / 60.0).clamp(0.0, 1.0);
      zenith = _lerpHex('#244B82', profile.dayZenithHex, t);
      horizon = _lerpHex('#A8CBE6', profile.dayHorizonHex, t);
      halo = _lerpHex('#FFD180', '#FFFDF4', t);
      ambient = 0.45 + 0.25 * t;
      direct = 0.85 + 0.15 * t;
    } else if (elev >= 0.0) {
      final t = (elev / 30.0).clamp(0.0, 1.0);
      zenith = _lerpHex(profile.sunsetZenithHex, '#244B82', t);
      horizon = _lerpHex('#D92B04', profile.sunsetHorizonHex, t);
      halo = _lerpHex('#FF5E1A', profile.sunHaloHex, t);
      ambient = 0.20 + 0.25 * t;
      direct = 0.35 + 0.50 * t;
    } else {
      final t = ((elev + 10.0) / 10.0).clamp(0.0, 1.0);
      zenith = _lerpHex(profile.nightZenithHex, profile.sunsetZenithHex, t);
      horizon = _lerpHex(profile.nightHorizonHex, '#7A1C08', t);
      halo = _lerpHex('#090D16', '#8C2D0C', t);
      ambient = 0.05 + 0.15 * t;
      direct = 0.35 * t;
    }

    return SolarHourState(
      isUnlocked: true,
      solarElevationDeg: elev,
      cameraAzimuthDeg: azimuth,
      zenithColorHex: _sanitizeNonWeincode(zenith),
      horizonColorHex: _sanitizeNonWeincode(horizon),
      sunHaloColorHex: _sanitizeNonWeincode(halo),
      shadowHardness: 0.65,
      ambientLightIntensity: ambient,
      directLightIntensity: direct,
    );
  }

  SolarHourState _evaluateMars(
    CelestialBody world,
    double elev,
    double azimuth,
  ) {
    final profile = world.skyOpticalProfile;
    String zenith;
    String horizon;
    String halo;
    double ambient;
    double direct;

    if (elev >= 25.0) {
      final t = ((elev - 25.0) / 65.0).clamp(0.0, 1.0);
      zenith = _lerpHex('#9C5D3B', profile.dayZenithHex, t);
      horizon = _lerpHex('#C48A62', profile.dayHorizonHex, t);
      halo = _lerpHex('#8FB8DE', '#B5CDE2', t);
      ambient = 0.35 + 0.20 * t;
      direct = 0.80 + 0.20 * t;
    } else if (elev >= 0.0) {
      final t = (elev / 25.0).clamp(0.0, 1.0);
      zenith = _lerpHex(profile.sunsetZenithHex, '#9C5D3B', t);
      horizon = _lerpHex(profile.sunsetHorizonHex, '#C48A62', t);
      // Cold blue circumsolar halo (Curiosity PIA19400)
      halo = _lerpHex(profile.sunHaloHex, '#8FB8DE', t);
      ambient = 0.18 + 0.17 * t;
      direct = 0.30 + 0.50 * t;
    } else {
      final t = ((elev + 10.0) / 10.0).clamp(0.0, 1.0);
      zenith = _lerpHex(profile.nightZenithHex, profile.sunsetZenithHex, t);
      horizon = _lerpHex(profile.nightHorizonHex, profile.sunsetHorizonHex, t);
      halo = _lerpHex('#1C2630', profile.sunHaloHex, t);
      ambient = 0.04 + 0.14 * t;
      direct = 0.30 * t;
    }

    return SolarHourState(
      isUnlocked: true,
      solarElevationDeg: elev,
      cameraAzimuthDeg: azimuth,
      zenithColorHex: _sanitizeNonWeincode(zenith),
      horizonColorHex: _sanitizeNonWeincode(horizon),
      sunHaloColorHex: _sanitizeNonWeincode(halo),
      shadowHardness: 0.55,
      ambientLightIntensity: ambient,
      directLightIntensity: direct,
    );
  }

  SolarHourState _evaluateMoon(
    CelestialBody world,
    double elev,
    double azimuth,
  ) {
    // Vacuum (rho = 0): permanent black sky, 0 ambient light, hard shadows (1.0),
    // abrupt cutoff of direct solar illumination at horizon (< 0°).
    final isSunAboveHorizon = elev >= 0.0;
    return SolarHourState(
      isUnlocked: true,
      solarElevationDeg: elev,
      cameraAzimuthDeg: azimuth,
      zenithColorHex: '#000000',
      horizonColorHex: '#000000',
      sunHaloColorHex: isSunAboveHorizon ? '#FFF8E7' : '#000000',
      shadowHardness: 1.0,
      ambientLightIntensity: 0.0,
      directLightIntensity: isSunAboveHorizon ? 1.0 : 0.0,
    );
  }

  SolarHourState _evaluateTitan(
    CelestialBody world,
    double elev,
    double azimuth,
  ) {
    final profile = world.skyOpticalProfile;
    String zenith;
    String horizon;
    String halo;
    double ambient;
    double direct;

    if (elev >= 20.0) {
      final t = ((elev - 20.0) / 70.0).clamp(0.0, 1.0);
      zenith = _lerpHex('#8C4210', profile.dayZenithHex, t);
      horizon = _lerpHex('#B5631E', profile.dayHorizonHex, t);
      halo = _lerpHex('#C96E24', profile.sunHaloHex, t);
      ambient = 0.55 + 0.20 * t;
      direct = 0.30 + 0.15 * t;
    } else if (elev >= 0.0) {
      final t = (elev / 20.0).clamp(0.0, 1.0);
      zenith = _lerpHex(profile.sunsetZenithHex, '#8C4210', t);
      horizon = _lerpHex(profile.sunsetHorizonHex, '#B5631E', t);
      halo = _lerpHex('#592608', '#C96E24', t);
      ambient = 0.25 + 0.30 * t;
      direct = 0.10 + 0.20 * t;
    } else {
      final t = ((elev + 10.0) / 10.0).clamp(0.0, 1.0);
      zenith = _lerpHex(profile.nightZenithHex, profile.sunsetZenithHex, t);
      horizon = _lerpHex(profile.nightHorizonHex, profile.sunsetHorizonHex, t);
      halo = _lerpHex('#120702', '#592608', t);
      ambient = 0.08 + 0.17 * t;
      direct = 0.10 * t;
    }

    return SolarHourState(
      isUnlocked: true,
      solarElevationDeg: elev,
      cameraAzimuthDeg: azimuth,
      zenithColorHex: _sanitizeNonWeincode(zenith),
      horizonColorHex: _sanitizeNonWeincode(horizon),
      sunHaloColorHex: _sanitizeNonWeincode(halo),
      shadowHardness: 0.15,
      ambientLightIntensity: ambient,
      directLightIntensity: direct,
    );
  }

  String _lerpHex(String startHex, String endHex, double t) {
    final s = _hexToRgb(startHex);
    final e = _hexToRgb(endHex);
    final clamped = t.clamp(0.0, 1.0);

    final r = (s.r + (e.r - s.r) * clamped).round().clamp(0, 255);
    final g = (s.g + (e.g - s.g) * clamped).round().clamp(0, 255);
    final b = (s.b + (e.b - s.b) * clamped).round().clamp(0, 255);

    return '#${r.toRadixString(16).padLeft(2, '0')}'
            '${g.toRadixString(16).padLeft(2, '0')}'
            '${b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  ({int r, int g, int b}) _hexToRgb(String hex) {
    final clean = hex.replaceFirst('#', '').trim();
    final value = int.parse(clean, radix: 16);
    return (
      r: (value >> 16) & 0xFF,
      g: (value >> 8) & 0xFF,
      b: value & 0xFF,
    );
  }

  String _sanitizeNonWeincode(String hex) {
    final upper = hex.toUpperCase();
    if (_forbiddenWeincodeColors.contains(upper)) {
      return '#19094E';
    }
    return upper;
  }
}
