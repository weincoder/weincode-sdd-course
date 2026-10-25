import {
  CelestialBody,
  CelestialBodyId,
  SkyOpticalProfile,
  TerrainTheme,
} from '../../../../domain/models/celestial-body/celestial-body';
import { CameraMode } from '../../../../domain/models/scene/camera-mode';
import { SceneLightingState } from '../../../../domain/models/scene/scene-lighting-state';
import { TerrainLayout } from '../../../../domain/models/scene/terrain-layout';
import { VisualQuality } from '../../../../domain/models/scene/visual-quality';
import { LanderState, LanderStatus } from '../../../../domain/models/simulation/lander-state';

export type LanderNodeName = 'Lander_Intact' | 'Lander_Destroyed';

export interface LanderVisualState {
  readonly altitudeMeters: number;
  readonly status: LanderStatus;
  readonly isThrusterActive: boolean;
  readonly visibleNodeName: LanderNodeName;
  readonly showThrusterFlame: boolean;
}

export interface QualitySettings {
  readonly level: VisualQuality;
  readonly shadowMapSize: 2048 | 1024;
  readonly softShadows: boolean;
  readonly terrainResolution: 192 | 64;
  readonly featureDensityRatio: 1.0 | 0.4;
  readonly atmosphericHazeEnabled: boolean;
  readonly maxPixelRatio: 2.0 | 1.25;
}

export interface SceneDescriptor {
  readonly worldId: CelestialBodyId;
  readonly terrainTheme: TerrainTheme;
  readonly skyOpticalProfile: SkyOpticalProfile;
  readonly lander: LanderVisualState;
  readonly lighting: SceneLightingState;
  readonly terrain: TerrainLayout;
  readonly cameraMode: CameraMode;
  readonly cameraAzimuthDeg: number;
  readonly quality: QualitySettings;
}

export interface SceneDescriptorMapperInput {
  readonly world: CelestialBody;
  readonly landerState: LanderState;
  readonly lighting: SceneLightingState;
  readonly terrain: TerrainLayout;
  readonly cameraMode: CameraMode;
  readonly cameraAzimuthDeg: number;
  readonly quality: VisualQuality;
}

const QUALITY_SETTINGS_BY_LEVEL: Record<VisualQuality, QualitySettings> = {
  high: {
    level: 'high',
    shadowMapSize: 2048,
    softShadows: true,
    terrainResolution: 192,
    featureDensityRatio: 1.0,
    atmosphericHazeEnabled: true,
    maxPixelRatio: 2.0,
  },
  basic: {
    level: 'basic',
    shadowMapSize: 1024,
    softShadows: false,
    terrainResolution: 64,
    featureDensityRatio: 0.4,
    atmosphericHazeEnabled: false,
    maxPixelRatio: 1.25,
  },
};

export const SceneDescriptorMapper = {
  from(input: SceneDescriptorMapperInput): SceneDescriptor {
    const { world, landerState, lighting, terrain, cameraMode, cameraAzimuthDeg, quality } = input;
    const isIntact = landerState.status === 'descending' || landerState.status === 'landed';
    const visibleNodeName: LanderNodeName = isIntact ? 'Lander_Intact' : 'Lander_Destroyed';
    const showThrusterFlame =
      landerState.status === 'descending' && Boolean(landerState.isThrusterActive);

    return {
      worldId: world.id,
      terrainTheme: world.terrainTheme,
      skyOpticalProfile: world.skyOpticalProfile,
      lander: {
        altitudeMeters: landerState.altitude,
        status: landerState.status,
        isThrusterActive: landerState.isThrusterActive,
        visibleNodeName,
        showThrusterFlame,
      },
      lighting,
      terrain,
      cameraMode,
      cameraAzimuthDeg,
      quality: { ...QUALITY_SETTINGS_BY_LEVEL[quality] },
    };
  },
};
