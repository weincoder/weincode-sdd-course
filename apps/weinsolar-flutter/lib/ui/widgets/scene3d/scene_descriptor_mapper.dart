import '../../../domain/models/celestial_body/celestial_body.dart';
import '../../../domain/models/scene/camera_mode.dart';
import '../../../domain/models/scene/scene_lighting_state.dart';
import '../../../domain/models/scene/terrain_layout.dart';
import '../../../domain/models/scene/visual_quality.dart';
import '../../../domain/models/simulation/lander_state.dart';

class LanderVisualState {
  final double altitudeMeters;
  final LanderStatus status;
  final bool isThrusterActive;
  final String visibleNodeName;
  final bool showThrusterFlame;

  const LanderVisualState({
    required this.altitudeMeters,
    required this.status,
    required this.isThrusterActive,
    required this.visibleNodeName,
    required this.showThrusterFlame,
  });
}

class QualitySettings {
  final VisualQuality level;
  final int shadowMapSize;
  final bool softShadows;
  final int terrainResolution;
  final double featureDensityRatio;
  final bool atmosphericHazeEnabled;
  final double maxPixelRatio;

  const QualitySettings({
    required this.level,
    required this.shadowMapSize,
    required this.softShadows,
    required this.terrainResolution,
    required this.featureDensityRatio,
    required this.atmosphericHazeEnabled,
    required this.maxPixelRatio,
  });

  int get shadowCascades => level == VisualQuality.high ? 2 : 1;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QualitySettings &&
        other.level == level &&
        other.shadowMapSize == shadowMapSize &&
        other.softShadows == softShadows &&
        other.terrainResolution == terrainResolution &&
        other.featureDensityRatio == featureDensityRatio &&
        other.atmosphericHazeEnabled == atmosphericHazeEnabled &&
        other.maxPixelRatio == maxPixelRatio;
  }

  @override
  int get hashCode => Object.hash(
        level,
        shadowMapSize,
        softShadows,
        terrainResolution,
        featureDensityRatio,
        atmosphericHazeEnabled,
        maxPixelRatio,
      );
}

class SceneDescriptor {
  final CelestialBodyId worldId;
  final TerrainTheme terrainTheme;
  final SkyOpticalProfile skyOpticalProfile;
  final LanderVisualState lander;
  final SceneLightingState lighting;
  final TerrainLayout terrain;
  final CameraMode cameraMode;
  final double cameraAzimuthDeg;
  final QualitySettings quality;

  const SceneDescriptor({
    required this.worldId,
    required this.terrainTheme,
    required this.skyOpticalProfile,
    required this.lander,
    required this.lighting,
    required this.terrain,
    required this.cameraMode,
    required this.cameraAzimuthDeg,
    required this.quality,
  });
}

class SceneDescriptorMapper {
  static const QualitySettings _highSettings = QualitySettings(
    level: VisualQuality.high,
    shadowMapSize: 2048,
    softShadows: true,
    terrainResolution: 192,
    featureDensityRatio: 1.0,
    atmosphericHazeEnabled: true,
    maxPixelRatio: 2.0,
  );

  static const QualitySettings _basicSettings = QualitySettings(
    level: VisualQuality.basic,
    shadowMapSize: 1024,
    softShadows: false,
    terrainResolution: 64,
    featureDensityRatio: 0.4,
    atmosphericHazeEnabled: false,
    maxPixelRatio: 1.25,
  );

  static SceneDescriptor from({
    required CelestialBody world,
    required LanderState landerState,
    required SceneLightingState lighting,
    required TerrainLayout terrain,
    required CameraMode cameraMode,
    required double cameraAzimuthDeg,
    required VisualQuality quality,
  }) {
    final isIntact = landerState.status == LanderStatus.descending ||
        landerState.status == LanderStatus.landed;
    final visibleNodeName = isIntact ? 'Lander_Intact' : 'Lander_Destroyed';
    final showThrusterFlame = landerState.status == LanderStatus.descending &&
        landerState.isThrusterActive;

    return SceneDescriptor(
      worldId: world.id,
      terrainTheme: world.terrainTheme,
      skyOpticalProfile: world.skyOpticalProfile,
      lander: LanderVisualState(
        altitudeMeters: landerState.altitude,
        status: landerState.status,
        isThrusterActive: landerState.isThrusterActive,
        visibleNodeName: visibleNodeName,
        showThrusterFlame: showThrusterFlame,
      ),
      lighting: lighting,
      terrain: terrain,
      cameraMode: cameraMode,
      cameraAzimuthDeg: cameraAzimuthDeg,
      quality: quality == VisualQuality.high ? _highSettings : _basicSettings,
    );
  }
}
