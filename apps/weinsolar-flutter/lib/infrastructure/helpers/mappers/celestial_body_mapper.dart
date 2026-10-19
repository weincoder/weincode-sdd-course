import '../../../domain/models/celestial_body/celestial_body.dart';

CelestialBody celestialBodyDataToEntity(Map<String, dynamic> raw) {
  final idStr = (raw['id'] as String? ?? '').trim().toLowerCase();
  final id = switch (idStr) {
    'earth' => CelestialBodyId.earth,
    'mars' => CelestialBodyId.mars,
    'moon' => CelestialBodyId.moon,
    'titan' => CelestialBodyId.titan,
    _ => throw ArgumentError('Unsupported CelestialBodyId: $idStr'),
  };

  final terrainMap = raw['terrainTheme'] as Map<String, dynamic>;
  final opticalMap = raw['skyOpticalProfile'] as Map<String, dynamic>;

  return CelestialBody(
    id: id,
    nameEs: raw['nameEs'] as String,
    gravity: (raw['gravity'] as num).toDouble(),
    atmosphericDensity: (raw['atmosphericDensity'] as num).toDouble(),
    timeScale: (raw['timeScale'] as num).toDouble(),
    initialAltitude: (raw['initialAltitude'] as num).toDouble(),
    ceilingAltitude: (raw['ceilingAltitude'] as num).toDouble(),
    initialVelocity: (raw['initialVelocity'] as num).toDouble(),
    initialFuel: (raw['initialFuel'] as num).toDouble(),
    terrainTheme: TerrainTheme(
      primarySurfaceHex: terrainMap['primarySurfaceHex'] as String,
      secondaryFeatureHex: terrainMap['secondaryFeatureHex'] as String,
      landingPadHex: terrainMap['landingPadHex'] as String,
      featureType: terrainMap['featureType'] as String,
    ),
    skyOpticalProfile: SkyOpticalProfile(
      scientificReference: opticalMap['scientificReference'] as String,
      dayZenithHex: opticalMap['dayZenithHex'] as String,
      dayHorizonHex: opticalMap['dayHorizonHex'] as String,
      sunsetZenithHex: opticalMap['sunsetZenithHex'] as String,
      sunsetHorizonHex: opticalMap['sunsetHorizonHex'] as String,
      nightZenithHex: opticalMap['nightZenithHex'] as String,
      nightHorizonHex: opticalMap['nightHorizonHex'] as String,
      sunHaloHex: opticalMap['sunHaloHex'] as String,
    ),
  );
}
