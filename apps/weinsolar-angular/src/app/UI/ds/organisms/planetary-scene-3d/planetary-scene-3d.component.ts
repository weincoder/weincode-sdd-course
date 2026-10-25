import {
  ChangeDetectionStrategy,
  Component,
  input,
  output,
} from '@angular/core';
import { NgtCanvas } from 'angular-three';
import {
  PLANETARY_SCENE_HOST,
  PlanetarySceneGraphComponent,
  PlanetarySceneHost,
} from './planetary-scene-graph.component';
import { SceneDescriptor } from './scene-descriptor.mapper';

@Component({
  selector: 'app-planetary-scene-3d',
  imports: [NgtCanvas],
  providers: [
    {
      provide: PLANETARY_SCENE_HOST,
      useExisting: PlanetaryScene3dComponent,
    },
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  styles: [
    `
      :host {
        display: block;
        width: 100%;
        height: 100%;
      }
      .scene-container {
        position: relative;
        width: 100%;
        height: 100%;
      }
    `,
  ],
  template: `
    <div class="scene-container" data-testid="planetary-scene-3d">
      <ngt-canvas
        [sceneGraph]="sceneGraph"
        [shadows]="true"
        data-testid="planetary-scene-canvas"
      />
    </div>
  `,
})
export class PlanetaryScene3dComponent implements PlanetarySceneHost {
  readonly descriptor = input.required<SceneDescriptor>();
  readonly cameraAzimuthChanged = output<number>();
  readonly sceneReady = output<void>();

  readonly sceneGraph = PlanetarySceneGraphComponent;

  notifyCameraAzimuthChanged(azimuthDeg: number): void {
    this.cameraAzimuthChanged.emit(azimuthDeg);
  }

  notifySceneReady(): void {
    this.sceneReady.emit();
  }
}
