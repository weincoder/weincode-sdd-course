import 'package:flutter_test/flutter_test.dart';
import 'package:weinsolar_flutter/domain/models/celestial_body/celestial_body.dart';
import 'package:weinsolar_flutter/domain/models/scene/camera_mode.dart';
import 'package:weinsolar_flutter/domain/models/scene/scene_lighting_state.dart';
import 'package:weinsolar_flutter/domain/models/scene/terrain_layout.dart';
import 'package:weinsolar_flutter/domain/models/scene/visual_quality.dart';
import 'package:weinsolar_flutter/domain/models/simulation/lander_state.dart';
import 'package:weinsolar_flutter/infrastructure/driven_adapters/celestial_body_local_adapter.dart';
import 'package:weinsolar_flutter/ui/widgets/scene3d/scene_descriptor_mapper.dart';

void main() {
  group('SceneDescriptorMapper (T034 — R6, RN-09..RN-15)', () {
    late CelestialBody earth;

    const mockLighting = SceneLightingState(
      solarElevationDeg: 65.0,
      sunDirection: Vector3Value(x: -0.397, y: 0.906, z: -0.144),
      sunColorHex: '#FFF4E0',
      sunIntensity: 1.0,
      ambientSkyColorHex: '#1E5799',
      ambientGroundColorHex: '#3D6B48',
      ambientIntensity: 0.45,
      shadowSoftness: 0.35,
      castsShadows: true,
      expectedShadowLengthRatio: 0.466,
    );

    const mockTerrain = TerrainLayout(
      sizeMeters: 600.0,
      resolution: 192,
      maxHeightMeters: 18.0,
      padRadiusMeters: 6.0,
      heights: [0.0, 0.0, 0.0, 0.0],
      features: [],
    );

    setUpAll(() async {
      earth = await const CelestialBodyLocalAdapter()
          .getById(CelestialBodyId.earth);
    });

    test('maps QualitySettings table (R6) accurately for high and basic', () {
      final baseLander = LanderState.initial(earth);

      final highDesc = SceneDescriptorMapper.from(
        world: earth,
        landerState: baseLander,
        lighting: mockLighting,
        terrain: mockTerrain,
        cameraMode: CameraMode.lateralFollow,
        cameraAzimuthDeg: 0.0,
        quality: VisualQuality.high,
      );

      expect(
        highDesc.quality,
        equals(
          const QualitySettings(
            level: VisualQuality.high,
            shadowMapSize: 2048,
            softShadows: true,
            terrainResolution: 192,
            featureDensityRatio: 1.0,
            atmosphericHazeEnabled: true,
            maxPixelRatio: 2.0,
          ),
        ),
      );

      final basicDesc = SceneDescriptorMapper.from(
        world: earth,
        landerState: baseLander,
        lighting: mockLighting,
        terrain: mockTerrain,
        cameraMode: CameraMode.orbit,
        cameraAzimuthDeg: 90.0,
        quality: VisualQuality.basic,
      );

      expect(
        basicDesc.quality,
        equals(
          const QualitySettings(
            level: VisualQuality.basic,
            shadowMapSize: 1024,
            softShadows: false,
            terrainResolution: 64,
            featureDensityRatio: 0.4,
            atmosphericHazeEnabled: false,
            maxPixelRatio: 1.25,
          ),
        ),
      );
    });

    test('derives LanderVisualState and visible node per LanderStatus', () {
      final descendingWithThrust = LanderState.initial(earth).copyWith(
        isThrusterActive: true,
        status: LanderStatus.descending,
      );
      final dDesc = SceneDescriptorMapper.from(
        world: earth,
        landerState: descendingWithThrust,
        lighting: mockLighting,
        terrain: mockTerrain,
        cameraMode: CameraMode.lateralFollow,
        cameraAzimuthDeg: 0.0,
        quality: VisualQuality.high,
      );
      expect(dDesc.lander.visibleNodeName, 'Lander_Intact');
      expect(dDesc.lander.showThrusterFlame, isTrue);

      final landedState = descendingWithThrust.copyWith(
        altitude: 0.0,
        status: LanderStatus.landed,
      );
      final lDesc = SceneDescriptorMapper.from(
        world: earth,
        landerState: landedState,
        lighting: mockLighting,
        terrain: mockTerrain,
        cameraMode: CameraMode.orbit,
        cameraAzimuthDeg: 45.0,
        quality: VisualQuality.high,
      );
      expect(lDesc.lander.visibleNodeName, 'Lander_Intact');
      expect(lDesc.lander.showThrusterFlame, isFalse);

      final crashedState = descendingWithThrust.copyWith(
        altitude: 0.0,
        status: LanderStatus.crashed,
      );
      final cDesc = SceneDescriptorMapper.from(
        world: earth,
        landerState: crashedState,
        lighting: mockLighting,
        terrain: mockTerrain,
        cameraMode: CameraMode.lateralFollow,
        cameraAzimuthDeg: 0.0,
        quality: VisualQuality.high,
      );
      expect(cDesc.lander.visibleNodeName, 'Lander_Destroyed');
      expect(cDesc.lander.showThrusterFlame, isFalse);

      final lostState = descendingWithThrust.copyWith(
        altitude: 760.0,
        status: LanderStatus.lostSignal,
      );
      final lostDesc = SceneDescriptorMapper.from(
        world: earth,
        landerState: lostState,
        lighting: mockLighting,
        terrain: mockTerrain,
        cameraMode: CameraMode.lateralFollow,
        cameraAzimuthDeg: 0.0,
        quality: VisualQuality.high,
      );
      expect(lostDesc.lander.visibleNodeName, 'Lander_Destroyed');
      expect(lostDesc.lander.showThrusterFlame, isFalse);
    });
  });
}
