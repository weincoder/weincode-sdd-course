import '../celestial_body/celestial_body.dart';

enum LanderStatus {
  descending,
  landed,
  crashed,
  lostSignal,
}

class LanderState {
  static const double defaultSafeLandingThreshold = 2.0;

  final double altitude;
  final double verticalVelocity;
  final double horizontalVelocity;
  final double fuelPercentage;
  final bool isThrusterActive;
  final LanderStatus status;
  final double safeLandingThreshold;
  final double ceilingAltitude;

  const LanderState({
    required this.altitude,
    required this.verticalVelocity,
    this.horizontalVelocity = 0.0,
    required this.fuelPercentage,
    required this.isThrusterActive,
    required this.status,
    this.safeLandingThreshold = defaultSafeLandingThreshold,
    this.ceilingAltitude = 750.0,
  });

  factory LanderState.initial(CelestialBody world) {
    return LanderState(
      altitude: world.initialAltitude,
      verticalVelocity: world.initialVelocity,
      horizontalVelocity: 0.0,
      fuelPercentage: world.initialFuel,
      isThrusterActive: false,
      status: LanderStatus.descending,
      safeLandingThreshold: defaultSafeLandingThreshold,
      ceilingAltitude: world.ceilingAltitude,
    );
  }

  bool get isVelocitySafe => verticalVelocity.abs() <= safeLandingThreshold;

  bool get isNearCeiling => altitude >= 0.85 * ceilingAltitude;

  bool get isOutOfFuel => fuelPercentage <= 0.0;

  LanderState copyWith({
    double? altitude,
    double? verticalVelocity,
    double? horizontalVelocity,
    double? fuelPercentage,
    bool? isThrusterActive,
    LanderStatus? status,
    double? safeLandingThreshold,
    double? ceilingAltitude,
  }) {
    return LanderState(
      altitude: altitude ?? this.altitude,
      verticalVelocity: verticalVelocity ?? this.verticalVelocity,
      horizontalVelocity: horizontalVelocity ?? this.horizontalVelocity,
      fuelPercentage: fuelPercentage ?? this.fuelPercentage,
      isThrusterActive: isThrusterActive ?? this.isThrusterActive,
      status: status ?? this.status,
      safeLandingThreshold: safeLandingThreshold ?? this.safeLandingThreshold,
      ceilingAltitude: ceilingAltitude ?? this.ceilingAltitude,
    );
  }
}
