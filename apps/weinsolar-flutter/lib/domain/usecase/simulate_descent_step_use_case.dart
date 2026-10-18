import '../models/celestial_body/celestial_body.dart';
import '../models/simulation/lander_state.dart';
import '../models/simulation/mission_attempt.dart';

class DescentStepResult {
  final LanderState state;
  final MissionAttempt attempt;

  const DescentStepResult({
    required this.state,
    required this.attempt,
  });
}

class SimulateDescentStepUseCase {
  static const double dragCoefficient = 0.0008;
  static const double maxThrustAcceleration = 24.0;
  static const double fuelConsumptionRatePerSecond = 3.5;
  static const double safeLandingThreshold = 2.0;
  static const double maxSimulatedSubstepSeconds = 0.05;

  const SimulateDescentStepUseCase();

  bool computeAutopilotThruster({
    required CelestialBody world,
    required LanderState state,
  }) {
    if (state.status != LanderStatus.descending || state.fuelPercentage <= 0.0) {
      return false;
    }
    final netUpwardAccel = maxThrustAcceleration - world.gravity;
    final speedDown = -state.verticalVelocity;
    final stoppingDistance = speedDown > 1.4
        ? (speedDown * speedDown - 1.4 * 1.4) / (2.0 * netUpwardAccel)
        : 0.0;

    if (state.altitude <= stoppingDistance + 8.0) {
      return state.verticalVelocity < -1.4;
    }
    return state.verticalVelocity < -28.0;
  }

  bool isAutopilotRecoverable({
    required CelestialBody world,
    required LanderState state,
  }) {
    if (state.fuelPercentage < 15.0) {
      return false;
    }
    final netUpwardAccel = maxThrustAcceleration - world.gravity;
    final speedDown = -state.verticalVelocity;
    final stoppingDistance = speedDown > 1.5
        ? (speedDown * speedDown - 1.5 * 1.5) / (2.0 * netUpwardAccel)
        : 0.0;
    return state.altitude > stoppingDistance + 6.0;
  }

  DescentStepResult execute({
    required CelestialBody world,
    required LanderState state,
    required MissionAttempt attempt,
    required double realDeltaSeconds,
  }) {
    if (attempt.outcome != MissionOutcome.inProgress ||
        state.status != LanderStatus.descending) {
      return DescentStepResult(state: state, attempt: attempt);
    }

    // Immediate surface contact evaluation if already at or below altitude 0
    if (state.altitude <= 0.0) {
      return _evaluateTouchdown(
        world: world,
        state: state,
        attempt: attempt,
        touchdownVelocity: state.verticalVelocity,
        remainingFuel: state.fuelPercentage,
      );
    }

    // Immediate ceiling evaluation if already above ceiling
    if (state.altitude > world.ceilingAltitude) {
      return _declareSignalLost(state: state, attempt: attempt);
    }

    if (realDeltaSeconds <= 0.0) {
      return DescentStepResult(state: state, attempt: attempt);
    }

    final totalSimulatedDelta = realDeltaSeconds * world.timeScale;
    final substeps =
        (totalSimulatedDelta / maxSimulatedSubstepSeconds).ceil().clamp(1, 200);
    final dt = totalSimulatedDelta / substeps;

    var currentAltitude = state.altitude;
    var currentVelocity = state.verticalVelocity;
    var currentFuel = state.fuelPercentage;
    final thrusterRequested = state.isThrusterActive;

    for (var i = 0; i < substeps; i++) {
      final hasFuel = currentFuel > 0.0;
      final effectiveThruster = thrusterRequested && hasFuel;

      var effectiveBurnTime = 0.0;
      if (effectiveThruster) {
        final maxBurnPossible = currentFuel / fuelConsumptionRatePerSecond;
        effectiveBurnTime = dt <= maxBurnPossible ? dt : maxBurnPossible;
        currentFuel =
            (currentFuel - fuelConsumptionRatePerSecond * effectiveBurnTime)
                .clamp(0.0, 100.0);
      }

      final thrustFraction = dt > 0.0 ? (effectiveBurnTime / dt) : 0.0;
      final thrustAccel =
          effectiveThruster ? maxThrustAcceleration * thrustFraction : 0.0;

      // Quadratic atmospheric drag opposing motion:
      // a_drag = -sign(v_y) * k_d * rho * v_y^2
      // On the Moon (rho == 0), drag is strictly 0.0 (RN-02, FR-005).
      final double dragAccel;
      if (world.atmosphericDensity <= 0.0 || currentVelocity == 0.0) {
        dragAccel = 0.0;
      } else {
        final sign = currentVelocity < 0.0 ? -1.0 : 1.0;
        dragAccel = -sign *
            dragCoefficient *
            world.atmosphericDensity *
            currentVelocity *
            currentVelocity;
      }

      final netAcceleration = -world.gravity + dragAccel + thrustAccel;
      final nextVelocity = currentVelocity + netAcceleration * dt;
      final nextAltitude = currentAltitude + nextVelocity * dt;

      // Check ceiling exceedance (1.5 * initialAltitude, RN-05, FR-024)
      if (nextAltitude > world.ceilingAltitude) {
        final lostState = state.copyWith(
          altitude: nextAltitude,
          verticalVelocity: nextVelocity,
          horizontalVelocity: 0.0,
          fuelPercentage: currentFuel,
          status: LanderStatus.lostSignal,
        );
        return _declareSignalLost(state: lostState, attempt: attempt);
      }

      // Check surface touchdown (altitude <= 0, RN-04, FR-009, FR-010)
      if (nextAltitude <= 0.0) {
        final totalDrop = currentAltitude - nextAltitude;
        final contactFraction =
            totalDrop > 1e-9 ? (currentAltitude / totalDrop).clamp(0.0, 1.0) : 1.0;
        final contactVelocity = currentVelocity +
            (nextVelocity - currentVelocity) * contactFraction;

        final landedState = state.copyWith(
          altitude: 0.0,
          verticalVelocity: contactVelocity,
          horizontalVelocity: 0.0,
          fuelPercentage: currentFuel,
        );
        return _evaluateTouchdown(
          world: world,
          state: landedState,
          attempt: attempt,
          touchdownVelocity: contactVelocity,
          remainingFuel: currentFuel,
        );
      }

      currentVelocity = nextVelocity;
      currentAltitude = nextAltitude;
    }

    final updatedState = state.copyWith(
      altitude: currentAltitude,
      verticalVelocity: currentVelocity,
      horizontalVelocity: 0.0,
      fuelPercentage: currentFuel,
      status: LanderStatus.descending,
    );

    final updatedAttempt = attempt.copyWith(
      remainingFuel: currentFuel,
    );

    return DescentStepResult(
      state: updatedState,
      attempt: updatedAttempt,
    );
  }

  DescentStepResult _declareSignalLost({
    required LanderState state,
    required MissionAttempt attempt,
  }) {
    final nextState = state.copyWith(
      status: LanderStatus.lostSignal,
      isThrusterActive: false,
      horizontalVelocity: 0.0,
    );
    final nextAttempt = attempt.copyWith(
      outcome: MissionOutcome.failedSignalLost,
      remainingFuel: state.fuelPercentage,
      isSolarHourUnlocked: false,
      failureReasonEs: 'Misión fallida – señal perdida',
    );
    return DescentStepResult(state: nextState, attempt: nextAttempt);
  }

  DescentStepResult _evaluateTouchdown({
    required CelestialBody world,
    required LanderState state,
    required MissionAttempt attempt,
    required double touchdownVelocity,
    required double remainingFuel,
  }) {
    final impactSpeed = touchdownVelocity.abs();
    final isSafe = impactSpeed <= safeLandingThreshold;

    if (isSafe) {
      final landedState = state.copyWith(
        altitude: 0.0,
        verticalVelocity: 0.0,
        horizontalVelocity: 0.0,
        fuelPercentage: remainingFuel,
        isThrusterActive: false,
        status: LanderStatus.landed,
      );
      final successAttempt = attempt.copyWith(
        outcome: MissionOutcome.success,
        touchdownVelocity: touchdownVelocity,
        remainingFuel: remainingFuel,
        isSolarHourUnlocked: true,
        failureReasonEs: null,
      );
      return DescentStepResult(state: landedState, attempt: successAttempt);
    } else {
      final crashedState = state.copyWith(
        altitude: 0.0,
        verticalVelocity: touchdownVelocity,
        horizontalVelocity: 0.0,
        fuelPercentage: remainingFuel,
        isThrusterActive: false,
        status: LanderStatus.crashed,
      );
      final failedAttempt = attempt.copyWith(
        outcome: MissionOutcome.failedImpact,
        touchdownVelocity: touchdownVelocity,
        remainingFuel: remainingFuel,
        isSolarHourUnlocked: false,
        failureReasonEs:
            'Impacto estructural severo a ${impactSpeed.toStringAsFixed(1)} m/s (límite seguro ≤ 2,0 m/s)',
      );
      return DescentStepResult(state: crashedState, attempt: failedAttempt);
    }
  }
}
