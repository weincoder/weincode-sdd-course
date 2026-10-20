import '../models/scene/camera_mode.dart';
import '../models/simulation/solar_hour_state.dart';

class ResolveCameraModeUseCase {
  const ResolveCameraModeUseCase();

  CameraMode execute(SolarHourState solarHour) {
    return solarHour.isUnlocked ? CameraMode.orbit : CameraMode.lateralFollow;
  }
}
