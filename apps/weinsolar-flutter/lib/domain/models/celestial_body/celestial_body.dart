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
  });

  String get scientificReference => skyOpticalProfile.scientificReference;
}
