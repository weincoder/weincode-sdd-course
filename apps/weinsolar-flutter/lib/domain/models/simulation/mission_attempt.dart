import '../celestial_body/celestial_body.dart';

enum MissionOutcome {
  inProgress,
  success,
  failedImpact,
  failedSignalLost,
  abandoned,
}

class MissionAttempt {
  final CelestialBodyId worldId;
  final MissionOutcome outcome;
  final double? touchdownVelocity;
  final double remainingFuel;
  final bool isSolarHourUnlocked;
  final String? failureReasonEs;

  const MissionAttempt({
    required this.worldId,
    required this.outcome,
    this.touchdownVelocity,
    required this.remainingFuel,
    required this.isSolarHourUnlocked,
    this.failureReasonEs,
  });

  factory MissionAttempt.initial(CelestialBody world) {
    return MissionAttempt(
      worldId: world.id,
      outcome: MissionOutcome.inProgress,
      touchdownVelocity: null,
      remainingFuel: world.initialFuel,
      isSolarHourUnlocked: false,
      failureReasonEs: null,
    );
  }

  MissionAttempt copyWith({
    CelestialBodyId? worldId,
    MissionOutcome? outcome,
    double? touchdownVelocity,
    double? remainingFuel,
    bool? isSolarHourUnlocked,
    String? failureReasonEs,
  }) {
    return MissionAttempt(
      worldId: worldId ?? this.worldId,
      outcome: outcome ?? this.outcome,
      touchdownVelocity: touchdownVelocity ?? this.touchdownVelocity,
      remainingFuel: remainingFuel ?? this.remainingFuel,
      isSolarHourUnlocked: isSolarHourUnlocked ?? this.isSolarHourUnlocked,
      failureReasonEs: failureReasonEs ?? this.failureReasonEs,
    );
  }
}
