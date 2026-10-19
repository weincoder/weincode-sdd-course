class SolarHourState {
  static const double minElevationDeg = -10.0;
  static const double maxElevationDeg = 90.0;
  static const double defaultInitialElevationDeg = 65.0;

  final bool isUnlocked;
  final double solarElevationDeg;
  final double cameraAzimuthDeg;
  final String zenithColorHex;
  final String horizonColorHex;
  final String sunHaloColorHex;
  final double shadowHardness;
  final double ambientLightIntensity;
  final double directLightIntensity;

  const SolarHourState({
    required this.isUnlocked,
    required this.solarElevationDeg,
    required this.cameraAzimuthDeg,
    required this.zenithColorHex,
    required this.horizonColorHex,
    required this.sunHaloColorHex,
    required this.shadowHardness,
    required this.ambientLightIntensity,
    this.directLightIntensity = 1.0,
  });

  factory SolarHourState.locked() {
    return const SolarHourState(
      isUnlocked: false,
      solarElevationDeg: defaultInitialElevationDeg,
      cameraAzimuthDeg: 0.0,
      zenithColorHex: '#000000',
      horizonColorHex: '#000000',
      sunHaloColorHex: '#000000',
      shadowHardness: 0.5,
      ambientLightIntensity: 0.0,
      directLightIntensity: 0.0,
    );
  }

  SolarHourState copyWith({
    bool? isUnlocked,
    double? solarElevationDeg,
    double? cameraAzimuthDeg,
    String? zenithColorHex,
    String? horizonColorHex,
    String? sunHaloColorHex,
    double? shadowHardness,
    double? ambientLightIntensity,
    double? directLightIntensity,
  }) {
    return SolarHourState(
      isUnlocked: isUnlocked ?? this.isUnlocked,
      solarElevationDeg: solarElevationDeg ?? this.solarElevationDeg,
      cameraAzimuthDeg: cameraAzimuthDeg ?? this.cameraAzimuthDeg,
      zenithColorHex: zenithColorHex ?? this.zenithColorHex,
      horizonColorHex: horizonColorHex ?? this.horizonColorHex,
      sunHaloColorHex: sunHaloColorHex ?? this.sunHaloColorHex,
      shadowHardness: shadowHardness ?? this.shadowHardness,
      ambientLightIntensity:
          ambientLightIntensity ?? this.ambientLightIntensity,
      directLightIntensity: directLightIntensity ?? this.directLightIntensity,
    );
  }
}
