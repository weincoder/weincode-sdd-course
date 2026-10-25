enum CelestialBodyId {
  earth,
  mars,
  moon,
  titan,
}

class TerrainTheme {
  final String primarySurfaceHex;
  final String secondaryFeatureHex;
  final String landingPadHex;
  final String featureType;

  const TerrainTheme({
    required this.primarySurfaceHex,
    required this.secondaryFeatureHex,
    required this.landingPadHex,
    required this.featureType,
  });
}

class SkyOpticalProfile {
  final String scientificReference;
  final String dayZenithHex;
  final String dayHorizonHex;
  final String sunsetZenithHex;
  final String sunsetHorizonHex;
  final String nightZenithHex;
  final String nightHorizonHex;
  final String sunHaloHex;

  const SkyOpticalProfile({
    required this.scientificReference,
    required this.dayZenithHex,
    required this.dayHorizonHex,
    required this.sunsetZenithHex,
    required this.sunsetHorizonHex,
    required this.nightZenithHex,
    required this.nightHorizonHex,
    required this.sunHaloHex,
  });
}

class LightingProfile {
  final double sunAzimuthDeg;
  final String sunColorDayHex;
  final String sunColorSunsetHex;
  final double ambientDayIntensity;
  final double twilightFadeDeg;
  final double shadowSoftness;
  final String scientificReference;

  const LightingProfile({
    required this.sunAzimuthDeg,
    required this.sunColorDayHex,
    required this.sunColorSunsetHex,
    required this.ambientDayIntensity,
    required this.twilightFadeDeg,
    required this.shadowSoftness,
    required this.scientificReference,
  });
}

class CelestialBody {
  final CelestialBodyId id;
  final String nameEs;
  final double gravity;
  final double atmosphericDensity;
  final double timeScale;
  final double initialAltitude;
  final double ceilingAltitude;
  final double initialVelocity;
  final double initialFuel;
  final TerrainTheme terrainTheme;
  final SkyOpticalProfile skyOpticalProfile;
  final LightingProfile lightingProfile;

  const CelestialBody({
    required this.id,
    required this.nameEs,
    required this.gravity,
    required this.atmosphericDensity,
    required this.timeScale,
    required this.initialAltitude,
    required this.ceilingAltitude,
    required this.initialVelocity,
    required this.initialFuel,
    required this.terrainTheme,
    required this.skyOpticalProfile,
    required this.lightingProfile,
  });

  String get scientificReference => skyOpticalProfile.scientificReference;
}
