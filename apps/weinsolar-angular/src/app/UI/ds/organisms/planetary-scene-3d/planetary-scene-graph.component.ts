import {
  CUSTOM_ELEMENTS_SCHEMA,
  ChangeDetectionStrategy,
  Component,
  InjectionToken,
  Signal,
  computed,
  effect,
  inject,
  signal,
} from '@angular/core';
import { injectStore } from 'angular-three';
import { Color } from 'three';
import { LanderModelComponent } from './lander-model.component';
import { SceneCameraRigComponent } from './scene-camera-rig.component';
import { SceneDescriptor } from './scene-descriptor.mapper';
import { SunLightComponent } from './sun-light.component';
import { TerrainMeshComponent } from './terrain-mesh.component';

export interface PlanetarySceneHost {
  readonly descriptor: Signal<SceneDescriptor>;
  notifyCameraAzimuthChanged(azimuthDeg: number): void;
  notifySceneReady(): void;
}

export const PLANETARY_SCENE_HOST = new InjectionToken<PlanetarySceneHost>(
  'PLANETARY_SCENE_HOST',
);

@Component({
  selector: 'app-planetary-scene-graph',
  imports: [
    LanderModelComponent,
    TerrainMeshComponent,
    SunLightComponent,
    SceneCameraRigComponent,
  ],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (descriptor(); as desc) {
      <app-sun-light
        [lighting]="desc.lighting"
        [quality]="desc.quality"
        [landerAltitude]="desc.lander.altitudeMeters"
        [hasAtmosphere]="desc.skyOpticalProfile.hasAtmosphere"
        [skyProfile]="desc.skyOpticalProfile"
        [worldId]="desc.worldId"
      />

      <app-terrain-mesh
        [terrain]="desc.terrain"
        [theme]="desc.terrainTheme"
        [quality]="desc.quality"
        (terrainReady)="onTerrainReady()"
      />

      <app-lander-model
        [lander]="desc.lander"
        [lighting]="desc.lighting"
        [worldId]="desc.worldId"
        (modelReady)="onModelReady()"
      />

      <app-scene-camera-rig
        [cameraMode]="desc.cameraMode"
        [landerAltitude]="desc.lander.altitudeMeters"
        [cameraAzimuthDeg]="desc.cameraAzimuthDeg"
        [sunDirection]="desc.lighting.sunDirection"
        (cameraAzimuthChanged)="onCameraAzimuthChanged($event)"
      />
    }
  `,
})
export class PlanetarySceneGraphComponent {
  private readonly host = inject(PLANETARY_SCENE_HOST, { optional: true });
  private readonly store = injectStore();

  readonly descriptor = computed<SceneDescriptor | null>(
    () => this.host?.descriptor() ?? null,
  );

  private readonly isModelReady = signal(false);
  private readonly isTerrainReady = signal(false);
  private hasEmittedSceneReady = false;

  constructor() {
    effect(() => {
      const desc = this.descriptor();
      if (!desc) {
        return;
      }

      const scene = this.store.snapshot.scene;
      if (scene) {
        scene.background = new Color(desc.lighting.ambientSkyColorHex);
      }

      const gl = this.store.snapshot.gl;
      if (gl && typeof window !== 'undefined') {
        const dpr = Math.min(window.devicePixelRatio || 1, desc.quality.maxPixelRatio);
        gl.setPixelRatio(dpr);
      }
    });

    effect(() => {
      if (this.isModelReady() && this.isTerrainReady() && !this.hasEmittedSceneReady) {
        this.hasEmittedSceneReady = true;
        this.host?.notifySceneReady();
      }
    });
  }

  onModelReady(): void {
    this.isModelReady.set(true);
  }

  onTerrainReady(): void {
    this.isTerrainReady.set(true);
  }

  onCameraAzimuthChanged(azimuthDeg: number): void {
    this.host?.notifyCameraAzimuthChanged(azimuthDeg);
  }
}
