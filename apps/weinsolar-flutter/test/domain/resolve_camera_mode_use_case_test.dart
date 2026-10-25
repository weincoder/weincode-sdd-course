import 'package:flutter_test/flutter_test.dart';
import 'package:weinsolar_flutter/domain/models/scene/camera_mode.dart';
import 'package:weinsolar_flutter/domain/models/simulation/solar_hour_state.dart';
import 'package:weinsolar_flutter/domain/usecase/resolve_camera_mode_use_case.dart';

void main() {
  group('ResolveCameraModeUseCase (T014 — RN-11)', () {
    const useCase = ResolveCameraModeUseCase();

    test('returns lateralFollow for SolarHourState.locked() (RN-11)', () {
      expect(
        useCase.execute(SolarHourState.locked()),
        equals(CameraMode.lateralFollow),
      );
    });

    test('returns orbit when SolarHourState.isUnlocked is true (RN-11)', () {
      final unlocked = SolarHourState.locked().copyWith(isUnlocked: true);
      expect(useCase.execute(unlocked), equals(CameraMode.orbit));
    });
  });
}
