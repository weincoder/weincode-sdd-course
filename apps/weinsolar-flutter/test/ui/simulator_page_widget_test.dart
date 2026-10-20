import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weinsolar_flutter/config/providers/simulation_provider.dart';
import 'package:weinsolar_flutter/domain/models/scene/camera_mode.dart';
import 'package:weinsolar_flutter/domain/models/scene/visual_quality.dart';
import 'package:weinsolar_flutter/domain/usecase/evaluate_solar_hour_use_case.dart';
import 'package:weinsolar_flutter/domain/usecase/get_celestial_bodies_use_case.dart';
import 'package:weinsolar_flutter/domain/usecase/simulate_descent_step_use_case.dart';
import 'package:weinsolar_flutter/infrastructure/driven_adapters/celestial_body_local_adapter.dart';
import 'package:weinsolar_flutter/main.dart';
import 'package:weinsolar_flutter/ui/widgets/weincode_cockpit_hud.dart';

void main() {
  group('SimulatorPage Widget Tests (v1 + v2 3D Scene US1..US4)', () {
    late SimulationProvider provider;

    setUp(() async {
      provider = SimulationProvider(
        getCelestialBodiesUseCase: const GetCelestialBodiesUseCase(
          gateway: CelestialBodyLocalAdapter(),
        ),
        simulateDescentStepUseCase: const SimulateDescentStepUseCase(),
        evaluateSolarHourUseCase: const EvaluateSolarHourUseCase(),
      );
      await provider.loadWorlds();
    });

    testWidgets('displays 4 worlds in Spanish with surface gravity on selection screen (FR-001, FR-002)', (tester) async {
      await tester.pumpWidget(WeinSolarApp(simulationProvider: provider));
      await tester.pump();

      expect(find.byKey(const Key('world-selector-sheet')), findsOneWidget);
      expect(find.text('Tierra'), findsOneWidget);
      expect(find.text('Marte'), findsOneWidget);
      expect(find.text('Luna'), findsOneWidget);
      expect(find.text('Titán'), findsOneWidget);
      expect(find.textContaining('9,81 m/s²'), findsOneWidget);
      expect(find.textContaining('3,71 m/s²'), findsOneWidget);
      expect(find.textContaining('1,62 m/s²'), findsOneWidget);
      expect(find.textContaining('1,352 m/s²'), findsOneWidget);
    });

    testWidgets('renders Weincode Cockpit HUD telemetry in Spanish and supports in-flight reset (FR-018..FR-021, FR-026)', (tester) async {
      await tester.pumpWidget(WeinSolarApp(simulationProvider: provider));
      await tester.pump();

      await tester.tap(find.byKey(const Key('world-card-mars')));
      await tester.pump();

      expect(find.byKey(const Key('weincode-cockpit-hud')), findsOneWidget);
      expect(find.text('×3'), findsOneWidget);
      expect(find.textContaining('Marte • g = 3,71 m/s²'), findsOneWidget);
      expect(find.text('500,0 m'), findsOneWidget);
      expect(find.text('-20,0 m/s'), findsOneWidget);
      expect(find.text('PELIGRO (> 2,0 m/s)'), findsOneWidget);
      expect(find.text('100,0%'), findsOneWidget);

      final hudContainer = tester.widget<Container>(
        find.byKey(const Key('weincode-cockpit-hud')),
      );
      final decoration = hudContainer.decoration! as BoxDecoration;
      expect(decoration.color, WeincodeCockpitHud.weincodeIndigoDeep);

      provider.setThrusterActive(true);
      provider.stepSimulation(0.05);
      await tester.pump();

      expect(provider.landerState!.altitude, lessThan(500.0));
      expect(provider.landerState!.fuelPercentage, lessThan(100.0));

      await tester.tap(find.byKey(const Key('in-flight-reset-button')));
      await tester.pump();

      expect(provider.landerState!.altitude, 500.0);
      expect(provider.landerState!.verticalVelocity, -20.0);
      expect(provider.landerState!.fuelPercentage, 100.0);
    });

    testWidgets('blocks Solar Hour after crash and allows Retry or Change World (FR-011, FR-012, FR-017, SC-004)', (tester) async {
      await tester.pumpWidget(WeinSolarApp(simulationProvider: provider));
      await tester.pump();

      await tester.tap(find.byKey(const Key('world-card-moon')));
      await tester.pump();

      for (var i = 0; i < 400 && provider.isDescending; i++) {
        provider.stepSimulation(0.05);
      }
      await tester.pump();

      expect(find.byKey(const Key('mission-outcome-overlay')), findsOneWidget);
      expect(find.text('Misión fallida'), findsOneWidget);
      expect(find.byKey(const Key('solar-hour-control-panel')), findsNothing);

      await tester.tap(find.byKey(const Key('retry-mission-button')));
      await tester.pump();

      expect(provider.isDescending, isTrue);
      expect(provider.landerState!.altitude, 500.0);
      expect(provider.isSolarHourUnlocked, isFalse);

      for (var i = 0; i < 400 && provider.isDescending; i++) {
        provider.stepSimulation(0.05);
      }
      await tester.pump();

      await tester.tap(find.byKey(const Key('change-world-button')));
      await tester.pump();

      expect(find.byKey(const Key('world-selector-sheet')), findsOneWidget);
    });

    testWidgets('unlocks Solar Hour after soft landing (<= 2.0 m/s) and relocks on Retry (FR-013, FR-014, FR-017, FR-029)', (tester) async {
      await tester.pumpWidget(WeinSolarApp(simulationProvider: provider));
      await tester.pump();

      await tester.tap(find.byKey(const Key('world-card-mars')));
      await tester.pump();

      final world = provider.selectedWorld!;
      final netUpwardAccel =
          SimulateDescentStepUseCase.maxThrustAcceleration - world.gravity;

      for (var i = 0; i < 2000 && provider.isDescending; i++) {
        final state = provider.landerState!;
        final speedDown = -state.verticalVelocity;
        final stoppingDistance = speedDown > 1.4
            ? (speedDown * speedDown - 1.4 * 1.4) / (2.0 * netUpwardAccel)
            : 0.0;
        final shouldBurn = state.altitude <= stoppingDistance + 8.0 &&
            state.verticalVelocity < -1.4;
        provider.setThrusterActive(shouldBurn);
        provider.stepSimulation(0.01);
      }
      await tester.pump();

      expect(provider.isSolarHourUnlocked, isTrue);
      expect(find.text('Aterrizaje exitoso'), findsOneWidget);
      expect(find.byKey(const Key('solar-hour-control-panel')), findsOneWidget);
      expect(find.text('VELOCIDAD SEGURA (≤ 2,0 m/s)'), findsOneWidget);

      provider.updateSolarElevation(8.0);
      provider.updateCameraAzimuth(135.0);
      await tester.pump();

      expect(provider.solarHourState.solarElevationDeg, 8.0);
      expect(provider.solarHourState.cameraAzimuthDeg, 135.0);

      await tester.tap(find.byKey(const Key('retry-mission-button')));
      await tester.pump();

      expect(provider.isSolarHourUnlocked, isFalse);
      expect(find.byKey(const Key('solar-hour-control-panel')), findsNothing);
    });

    testWidgets('auto-land button (Aterrizaje automático) guides lander to safe touchdown and unlocks Solar Hour', (tester) async {
      await tester.pumpWidget(WeinSolarApp(simulationProvider: provider));
      await tester.pump();

      await tester.tap(find.byKey(const Key('world-card-earth')));
      await tester.pump();

      expect(find.byKey(const Key('auto-land-button')), findsOneWidget);
      expect(find.text('Aterrizaje automático'), findsOneWidget);

      await tester.tap(find.byKey(const Key('auto-land-button')));
      await tester.pump();

      expect(provider.isAutopilotActive, isTrue);
      expect(find.text('Piloto automático: ACTIVO'), findsOneWidget);

      for (var i = 0; i < 3000 && provider.isDescending; i++) {
        provider.stepSimulation(0.01);
      }
      await tester.pump();

      expect(provider.isSolarHourUnlocked, isTrue);
      expect(find.text('Aterrizaje exitoso'), findsOneWidget);
      expect(find.byKey(const Key('solar-hour-control-panel')), findsOneWidget);
    });

    testWidgets('T040 (US1): maps LanderVisualState and CameraMode across descending, thruster active, landed, and crashed states', (tester) async {
      await tester.pumpWidget(WeinSolarApp(simulationProvider: provider));
      await tester.pump();

      await tester.tap(find.byKey(const Key('world-card-mars')));
      await tester.pump();

      expect(provider.cameraMode, CameraMode.lateralFollow);
      expect(provider.sceneDescriptor!.lander.visibleNodeName, 'Lander_Intact');
      expect(provider.sceneDescriptor!.lander.showThrusterFlame, isFalse);

      provider.setThrusterActive(true);
      await tester.pump();
      expect(provider.sceneDescriptor!.lander.showThrusterFlame, isTrue);

      provider.setThrusterActive(false);
      for (var i = 0; i < 400 && provider.isDescending; i++) {
        provider.stepSimulation(0.05);
      }
      await tester.pump();

      expect(provider.cameraMode, CameraMode.lateralFollow);
      expect(
        provider.sceneDescriptor!.lander.visibleNodeName,
        'Lander_Destroyed',
      );
      expect(provider.sceneDescriptor!.lander.showThrusterFlame, isFalse);
      expect(provider.isSolarHourUnlocked, isFalse);
    });

    testWidgets('T061 (US4): QualityToggle hot-switches VisualQuality between high and basic without resetting flight state', (tester) async {
      await tester.pumpWidget(WeinSolarApp(simulationProvider: provider));
      await tester.pump();

      await tester.tap(find.byKey(const Key('world-card-earth')));
      await tester.pump();

      provider.stepSimulation(0.05);
      await tester.pump();
      final altitudeDuringFlight = provider.landerState!.altitude;
      expect(altitudeDuringFlight, lessThan(500.0));

      expect(provider.visualQuality, VisualQuality.high);
      expect(provider.sceneDescriptor!.quality.shadowMapSize, 2048);
      expect(provider.sceneDescriptor!.quality.terrainResolution, 192);
      expect(provider.sceneDescriptor!.quality.softShadows, isTrue);

      await tester.tap(find.byKey(const Key('quality-option-basic')));
      await tester.pump();

      expect(provider.visualQuality, VisualQuality.basic);
      expect(provider.sceneDescriptor!.quality.shadowMapSize, 1024);
      expect(provider.sceneDescriptor!.quality.terrainResolution, 64);
      expect(provider.sceneDescriptor!.quality.softShadows, isFalse);
      expect(provider.landerState!.altitude, altitudeDuringFlight);
      expect(provider.isDescending, isTrue);
    });

    testWidgets('T071 (US2): Solar Hour slider updates SceneLightingState with longer shadows and world-specific twilight tints', (tester) async {
      await tester.pumpWidget(WeinSolarApp(simulationProvider: provider));
      await tester.pump();

      await tester.tap(find.byKey(const Key('world-card-mars')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('auto-land-button')));
      for (var i = 0; i < 3000 && provider.isDescending; i++) {
        provider.stepSimulation(0.01);
      }
      await tester.pump();

      expect(provider.isSolarHourUnlocked, isTrue);

      provider.updateSolarElevation(85.0);
      await tester.pump();
      final highSunLighting = provider.sceneLighting!;

      provider.updateSolarElevation(2.0);
      await tester.pump();
      final lowSunLighting = provider.sceneLighting!;

      expect(
        lowSunLighting.expectedShadowLengthRatio,
        greaterThan(highSunLighting.expectedShadowLengthRatio!),
      );
      expect(lowSunLighting.castsShadows, isTrue);

      // Mars at 2° has blue-dominant sunset tint (B > R)
      final marsHex =
          int.parse(lowSunLighting.sunColorHex.replaceFirst('#', ''), radix: 16);
      final marsR = (marsHex >> 16) & 0xFF;
      final marsB = marsHex & 0xFF;
      expect(marsB, greaterThan(marsR));
    });

    testWidgets('T080 & T084 (US3): restricts camera orbit to unlocked Solar Hour and supports drag/keyboard without v1 azimuth slider', (tester) async {
      await tester.pumpWidget(WeinSolarApp(simulationProvider: provider));
      await tester.pump();

      await tester.tap(find.byKey(const Key('world-card-titan')));
      await tester.pump();

      // During descent (CameraMode.lateralFollow), orbit mutations are ignored
      expect(provider.cameraMode, CameraMode.lateralFollow);
      provider.updateCameraAzimuth(120.0);
      provider.rotateCameraByDelta(45.0);
      expect(provider.solarHourState.cameraAzimuthDeg, 0.0);

      // Auto-land to unlock Solar Hour and enter CameraMode.orbit
      await tester.tap(find.byKey(const Key('auto-land-button')));
      for (var i = 0; i < 3000 && provider.isDescending; i++) {
        provider.stepSimulation(0.01);
      }
      await tester.pump();

      expect(provider.cameraMode, CameraMode.orbit);
      expect(find.byKey(const Key('solar-elevation-slider')), findsOneWidget);
      expect(find.byKey(const Key('camera-azimuth-slider')), findsNothing);

      // Keyboard arrow right/left orbits camera by ±5°
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(provider.solarHourState.cameraAzimuthDeg, closeTo(5.0, 1e-6));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(provider.solarHourState.cameraAzimuthDeg, closeTo(0.0, 1e-6));

      // Hide HUD velocity/telemetry controls so the 3D viewport center is completely unobstructed
      expect(find.byKey(const Key('toggle-hud-controls-button')), findsOneWidget);
      expect(find.text('Ocultar controles'), findsOneWidget);
      await tester.tap(find.byKey(const Key('toggle-hud-controls-button')));
      await tester.pump();

      expect(find.text('Mostrar controles'), findsOneWidget);
      expect(find.byKey(const Key('hud-velocity-value')), findsNothing);
      expect(find.byKey(const Key('mission-outcome-overlay')), findsNothing);

      // Horizontal drag on planetary-scene-view updates cameraAzimuthDeg cleanly
      await tester.drag(
        find.byKey(const Key('planetary-scene-view')),
        const Offset(100.0, 0.0),
      );
      await tester.pump();
      expect(provider.solarHourState.cameraAzimuthDeg, greaterThan(0.0));

      // Restore controls
      await tester.tap(find.byKey(const Key('toggle-hud-controls-button')));
      await tester.pump();
      expect(find.byKey(const Key('hud-velocity-value')), findsOneWidget);
    });
  });
}
