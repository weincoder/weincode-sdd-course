class Vector3Value {
  final double x;
  final double y;
  final double z;

  const Vector3Value({
    required this.x,
    required this.y,
    required this.z,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vector3Value &&
        other.x == x &&
        other.y == y &&
        other.z == z;
  }

  @override
  int get hashCode => Object.hash(x, y, z);
}

class SceneLightingState {
  final double solarElevationDeg;
  final Vector3Value sunDirection;
  final String sunColorHex;
  final double sunIntensity;
  final String ambientSkyColorHex;
  final String ambientGroundColorHex;
  final double ambientIntensity;
  final double shadowSoftness;
  final bool castsShadows;
  final double? expectedShadowLengthRatio;

  const SceneLightingState({
    required this.solarElevationDeg,
    required this.sunDirection,
    required this.sunColorHex,
    required this.sunIntensity,
    required this.ambientSkyColorHex,
    required this.ambientGroundColorHex,
    required this.ambientIntensity,
    required this.shadowSoftness,
    required this.castsShadows,
    required this.expectedShadowLengthRatio,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SceneLightingState &&
        other.solarElevationDeg == solarElevationDeg &&
        other.sunDirection == sunDirection &&
        other.sunColorHex == sunColorHex &&
        other.sunIntensity == sunIntensity &&
        other.ambientSkyColorHex == ambientSkyColorHex &&
        other.ambientGroundColorHex == ambientGroundColorHex &&
        other.ambientIntensity == ambientIntensity &&
        other.shadowSoftness == shadowSoftness &&
        other.castsShadows == castsShadows &&
        other.expectedShadowLengthRatio == expectedShadowLengthRatio;
  }

  @override
  int get hashCode => Object.hash(
        solarElevationDeg,
        sunDirection,
        sunColorHex,
        sunIntensity,
        ambientSkyColorHex,
        ambientGroundColorHex,
        ambientIntensity,
        shadowSoftness,
        castsShadows,
        expectedShadowLengthRatio,
      );
}
