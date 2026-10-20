import {
  CUSTOM_ELEMENTS_SCHEMA,
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  input,
  output,
} from '@angular/core';
import { NgtArgs, injectLoader } from 'angular-three';
import { Color, Mesh, MeshStandardMaterial, Object3D } from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
import { CelestialBodyId } from '../../../../domain/models/celestial-body/celestial-body';
import { SceneLightingState } from '../../../../domain/models/scene/scene-lighting-state';
import { LanderVisualState } from './scene-descriptor.mapper';

export const LANDER_GLB_ASSET_PATH = 'models/lander.glb';

export function preloadLanderGlb(): void {
  try {
    injectLoader.preload(
      () => GLTFLoader,
      () => LANDER_GLB_ASSET_PATH,
    );
  } catch {
    // Ignore preload errors in non-WebGL test environments
  }
}

@Component({
  selector: 'app-lander-model',
  imports: [NgtArgs],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <ngt-group [position]="position()">
      @if (gltfScene(); as sceneRoot) {
        <ngt-primitive *args="[sceneRoot]" />
      }

      <!-- Dynamic Rocket Plume Point Light illuminating the hull and landing pad during burn -->
      @if (lander().showThrusterFlame) {
        <ngt-point-light
          [position]="[0, -0.8, 0]"
          color="#FF8C2A"
          [intensity]="14.0"
          [distance]="24"
          [decay]="1.6"
        />
      }
    </ngt-group>
  `,
})
export class LanderModelComponent {
  readonly lander = input.required<LanderVisualState>();
  readonly lighting = input.required<SceneLightingState>();
  readonly worldId = input.required<CelestialBodyId>();

  readonly modelReady = output<void>();

  private hasEmittedReady = false;

  readonly gltf = injectLoader(
    () => GLTFLoader,
    () => LANDER_GLB_ASSET_PATH,
  );

  readonly gltfScene = computed<Object3D | null>(() => {
    const loaded = this.gltf();
    return loaded?.scene ?? null;
  });

  readonly position = computed<[number, number, number]>(() => [
    0,
    Math.max(0, this.lander().altitudeMeters),
    0,
  ]);

  constructor() {
    effect(() => {
      const root = this.gltfScene();
      const landerState = this.lander();
      const light = this.lighting();
      const world = this.worldId();
      if (!root) {
        return;
      }

      const intactNode = root.getObjectByName('Lander_Intact');
      const destroyedNode = root.getObjectByName('Lander_Destroyed');
      const flameNode = root.getObjectByName('Thruster_Flame');

      if (intactNode) {
        intactNode.visible = landerState.visibleNodeName === 'Lander_Intact';
      }
      if (destroyedNode) {
        destroyedNode.visible = landerState.visibleNodeName === 'Lander_Destroyed';
      }
      if (flameNode) {
        flameNode.visible = landerState.showThrusterFlame;
      }

      const isMoon = world === 'moon';
      const envIntensity = isMoon ? 0.0 : 1.25;
      const sunsetTint = new Color(light.sunColorHex);

      root.traverse((obj: Object3D) => {
        const mesh = obj as Mesh;
        if (mesh.isMesh) {
          mesh.castShadow = true;
          mesh.receiveShadow = true;
          const materials = Array.isArray(mesh.material) ? mesh.material : [mesh.material];
          for (const m of materials) {
            const mat = m as MeshStandardMaterial | undefined;
            if (mat && 'envMapIntensity' in mat && obj.name !== 'Thruster_Flame') {
              mat.envMapIntensity = envIntensity;
              if (!isMoon && light.solarElevationDeg <= 18) {
                mat.emissive.copy(sunsetTint);
                mat.emissiveIntensity = Math.max(0.06, light.ambientIntensity * 0.25);
              } else {
                mat.emissive.setHex(0x000000);
                mat.emissiveIntensity = 0.0;
              }
              mat.needsUpdate = true;
            }
          }
        }
      });

      if (!this.hasEmittedReady) {
        this.hasEmittedReady = true;
        this.modelReady.emit();
      }
    });
  }
}
