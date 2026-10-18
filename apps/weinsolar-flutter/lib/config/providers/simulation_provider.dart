import 'package:flutter/foundation.dart';

import '../../domain/models/celestial_body/celestial_body.dart';
import '../../domain/models/simulation/lander_state.dart';
import '../../domain/models/simulation/mission_attempt.dart';
import '../../domain/models/simulation/solar_hour_state.dart';
import '../../domain/usecase/evaluate_solar_hour_use_case.dart';
import '../../domain/usecase/get_celestial_bodies_use_case.dart';
import '../../domain/usecase/simulate_descent_step_use_case.dart';

class SimulationProvider extends ChangeNotifier {
  final GetCelestialBodiesUseCase getCelestialBodiesUseCase;
  final SimulateDescentStepUseCase simulateDescentStepUseCase;
  final EvaluateSolarHourUseCase evaluateSolarHourUseCase;

  List<CelestialBody> _worlds = const [];
  CelestialBody? _selectedWorld;
  LanderState? _landerState;
  MissionAttempt? _missionAttempt;
  SolarHourState _solarHourState = SolarHourState.locked();
  bool _isPaused = false;
  bool _isLoading = false;
  bool _isAutopilotActive = false;

  SimulationProvider({
    required this.getCelestialBodiesUseCase,
    this.simulateDescentStepUseCase = const SimulateDescentStepUseCase(),
    this.evaluateSolarHourUseCase = const EvaluateSolarHourUseCase(),
  });

  List<CelestialBody> get worlds => _worlds;
  CelestialBody? get selectedWorld => _selectedWorld;
  LanderState? get landerState => _landerState;
  MissionAttempt? get missionAttempt => _missionAttempt;
  SolarHourState get solarHourState => _solarHourState;
  bool get isPaused => _isPaused;
  bool get isLoading => _isLoading;
  bool get isAutopilotActive => _isAutopilotActive;

  bool get isWorldSelectionActive => _selectedWorld == null;

  bool get isDescending =>
      _selectedWorld != null &&
      _landerState?.status == LanderStatus.descending &&
      _missionAttempt?.outcome == MissionOutcome.inProgress;

  bool get isSolarHourUnlocked =>
      _missionAttempt?.outcome == MissionOutcome.success &&
      _missionAttempt?.isSolarHourUnlocked == true &&
      _solarHourState.isUnlocked;

  Future<void> loadWorlds() async {
    _isLoading = true;
    notifyListeners();
    try {
      _worlds = await getCelestialBodiesUseCase.execute();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectWorld(CelestialBody world) {
    _selectedWorld = world;
    _landerState = LanderState.initial(world);
    _missionAttempt = MissionAttempt.initial(world);
    _solarHourState = SolarHourState.locked();
    _isPaused = false;
    _isAutopilotActive = false;
    notifyListeners();
  }

  void toggleAutoLand() {
    final world = _selectedWorld;
    final currentLander = _landerState;
    final currentAttempt = _missionAttempt;
    if (world == null ||
        currentLander == null ||
        currentAttempt == null ||
        currentAttempt.outcome != MissionOutcome.inProgress ||
        currentLander.status != LanderStatus.descending) {
      return;
    }

    final nextActive = !_isAutopilotActive;
    if (nextActive &&
        !simulateDescentStepUseCase.isAutopilotRecoverable(
          world: world,
          state: currentLander,
        )) {
      _landerState = LanderState.initial(world);
      _missionAttempt = MissionAttempt.initial(world);
      _solarHourState = SolarHourState.locked();
    }

    _isAutopilotActive = nextActive;
    final activeLander = _landerState!;
    final shouldBurn = nextActive
        ? simulateDescentStepUseCase.computeAutopilotThruster(
            world: world,
            state: activeLander,
          )
        : false;
    _landerState = activeLander.copyWith(isThrusterActive: shouldBurn);
    notifyListeners();
  }

  void setThrusterActive(bool active) {
    final currentLander = _landerState;
    final currentAttempt = _missionAttempt;
    if (currentLander == null ||
        currentAttempt == null ||
        currentAttempt.outcome != MissionOutcome.inProgress ||
        currentLander.status != LanderStatus.descending) {
      return;
    }
    if (active && _isAutopilotActive) {
      _isAutopilotActive = false;
    }
    if (currentLander.isThrusterActive == active) {
      return;
    }
    _landerState = currentLander.copyWith(isThrusterActive: active);
    notifyListeners();
  }

  void stepSimulation(double realDeltaSeconds) {
    final world = _selectedWorld;
    final currentLander = _landerState;
    final currentAttempt = _missionAttempt;
    if (world == null ||
        currentLander == null ||
        currentAttempt == null ||
        _isPaused ||
        currentAttempt.outcome != MissionOutcome.inProgress) {
      return;
    }

    final clampedDelta = realDeltaSeconds.clamp(0.0, 0.05);
    if (clampedDelta <= 0.0) {
      return;
    }

    final stepState = _isAutopilotActive
        ? currentLander.copyWith(
            isThrusterActive:
                simulateDescentStepUseCase.computeAutopilotThruster(
              world: world,
              state: currentLander,
            ),
          )
        : currentLander;

    final result = simulateDescentStepUseCase.execute(
      world: world,
      state: stepState,
      attempt: currentAttempt,
      realDeltaSeconds: clampedDelta,
    );

    _landerState = result.state;
    _missionAttempt = result.attempt;

    if (result.attempt.outcome == MissionOutcome.success) {
      _isAutopilotActive = false;
      _solarHourState = evaluateSolarHourUseCase.execute(
        world: world,
        attempt: result.attempt,
        solarElevationDeg: SolarHourState.defaultInitialElevationDeg,
        cameraAzimuthDeg: 0.0,
      );
    } else if (result.attempt.outcome != MissionOutcome.inProgress) {
      _isAutopilotActive = false;
      _solarHourState = SolarHourState.locked();
    }

    notifyListeners();
  }

  void updateSolarElevation(double elevationDeg) {
    final world = _selectedWorld;
    final attempt = _missionAttempt;
    if (world == null || attempt == null) {
      return;
    }
    _solarHourState = evaluateSolarHourUseCase.execute(
      world: world,
      attempt: attempt,
      solarElevationDeg: elevationDeg,
      cameraAzimuthDeg: _solarHourState.cameraAzimuthDeg,
    );
    notifyListeners();
  }

  void updateCameraAzimuth(double azimuthDeg) {
    final world = _selectedWorld;
    final attempt = _missionAttempt;
    if (world == null || attempt == null) {
      return;
    }
    _solarHourState = evaluateSolarHourUseCase.execute(
      world: world,
      attempt: attempt,
      solarElevationDeg: _solarHourState.solarElevationDeg,
      cameraAzimuthDeg: azimuthDeg,
    );
    notifyListeners();
  }

  void rotateCameraByDelta(double deltaDeg) {
    if (!isSolarHourUnlocked) {
      return;
    }
    updateCameraAzimuth(_solarHourState.cameraAzimuthDeg + deltaDeg);
  }

  void resetInFlight() {
    final world = _selectedWorld;
    if (world == null) {
      return;
    }
    _landerState = LanderState.initial(world);
    _missionAttempt = MissionAttempt.initial(world);
    _solarHourState = SolarHourState.locked();
    _isPaused = false;
    _isAutopilotActive = false;
    notifyListeners();
  }

  void retryCurrentWorld() {
    final world = _selectedWorld;
    if (world == null) {
      return;
    }
    _landerState = LanderState.initial(world);
    _missionAttempt = MissionAttempt.initial(world);
    _solarHourState = SolarHourState.locked();
    _isPaused = false;
    _isAutopilotActive = false;
    notifyListeners();
  }

  void returnToWorldSelection() {
    _selectedWorld = null;
    _landerState = null;
    _missionAttempt = null;
    _solarHourState = SolarHourState.locked();
    _isPaused = false;
    _isAutopilotActive = false;
    notifyListeners();
  }

  void setPaused(bool paused) {
    if (_isPaused == paused) {
      return;
    }
    _isPaused = paused;
    if (paused && _landerState != null && _landerState!.isThrusterActive) {
      _landerState = _landerState!.copyWith(isThrusterActive: false);
    }
    notifyListeners();
  }
}
