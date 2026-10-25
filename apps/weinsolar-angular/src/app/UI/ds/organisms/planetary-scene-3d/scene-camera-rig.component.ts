import {
  CUSTOM_ELEMENTS_SCHEMA,
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  ViewChild,
  computed,
  effect,
  input,
  output,
} from '@angular/core';
import { NgtArgs, injectBeforeRender, injectStore } from 'angular-three';
import { Vector3 } from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
import { CameraMode } from '../../../../domain/models/scene/camera-mode';
import { Vector3Like } from '../../../../domain/models/scene/scene-lighting-state';

const LATERAL_ELEVATION_RAD = (14 * Math.PI) / 180;
const MIN_POLAR_ANGLE_RAD = (25 * Math.PI) / 180;
const MAX_POLAR_ANGLE_RAD = (86 * Math.PI) / 180;
const ORBIT_INITIAL_DISTANCE = 15.5;
const ORBIT_TARGET_Y = 1.6;

@Component({
  selector: 'app-scene-camera-rig',
  imports: [NgtArgs],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (camera() && domElement()) {
      <ngt-orbit-controls
        #orbitControls
        *args="[camera(), domElement()]"
        [enabled]="isOrbitMode()"
        [enablePan]="false"
        [enableDamping]="true"
        [dampingFactor]="0.08"
        [minDistance]="6"
        [maxDistance]="48"
        [minPolarAngle]="minPolarAngle"
        [maxPolarAngle]="maxPolarAngle"
        (change)="onOrbitChange()"
      />
    }
  `,
})
export class SceneCameraRigComponent {
  @ViewChild('orbitControls')
  private readonly controlsRef?: ElementRef<OrbitControls>;

  readonly cameraMode = input.required<CameraMode>();
  readonly landerAltitude = input.required<number>();
  readonly cameraAzimuthDeg = input.required<number>();
  readonly sunDirection = input<Vector3Like>({ x: -0.5, y: 0.8, z: -0.5 });

  readonly cameraAzimuthChanged = output<number>();

  private readonly store = injectStore();
  readonly camera = this.store.select('camera');
  readonly domElement = computed(() => this.store.snapshot.gl?.domElement ?? null);
  readonly isOrbitMode = computed(() => this.cameraMode() === 'orbit');

  readonly minPolarAngle = MIN_POLAR_ANGLE_RAD;
  readonly maxPolarAngle = MAX_POLAR_ANGLE_RAD;

  private readonly desiredPos = new Vector3();
  private readonly desiredTarget = new Vector3();
  private readonly currentTarget = new Vector3(0, 250, 0);
  private previousMode: CameraMode | null = null;
  private lastAppliedAzimuthDeg: number | null = null;
  private isInternalControlUpdate = false;

  constructor() {
    effect(() => {
      const mode = this.cameraMode();
      const cam = this.camera();
      const azimuthDeg = this.cameraAzimuthDeg();
      const sunDir = this.sunDirection();
      if (!cam) {
        return;
      }

      if (mode === 'orbit' && this.previousMode !== 'orbit') {
        // Place camera opposite the sun horizontally so the lander, its shadow, and the sun in the sky are framed together
        const sunAzRad = Math.atan2(sunDir.x, sunDir.z);
        const sunAzDeg = ((sunAzRad * 180) / Math.PI + 360) % 360;
        const initialAzimuthDeg = azimuthDeg === 0 ? (sunAzDeg + 180) % 360 : azimuthDeg;
        this.applyOrbitCameraPose(cam, initialAzimuthDeg);
        this.lastAppliedAzimuthDeg = azimuthDeg;
      } else if (
        mode === 'orbit' &&
        this.lastAppliedAzimuthDeg !== null &&
        Math.abs(azimuthDeg - this.lastAppliedAzimuthDeg) > 0.5
      ) {
        this.applyOrbitCameraPose(cam, azimuthDeg);
        this.lastAppliedAzimuthDeg = azimuthDeg;
      }

      this.previousMode = mode;
    });

    injectBeforeRender(({ camera, delta }) => {
      const mode = this.cameraMode();
      if (mode === 'lateralFollow') {
        const alt = Math.max(0, this.landerAltitude());
        const sunDir = this.sunDirection();
        const sunAzDeg = ((Math.atan2(sunDir.x, sunDir.z) * 180) / Math.PI + 360) % 360;
        const followAzRad = (((sunAzDeg + 194) % 360) * Math.PI) / 180;
        // Keep the lander closely framed (14.5..22 m) while showing the terrain below and sun/horizon behind it
        const dist = Math.min(22, Math.max(14.5, 14.5 + alt * 0.015));
        const targetY = Math.max(1.8, alt + 1.8);
        const camY = alt + 2.8;
        const camX = Math.sin(followAzRad) * dist;
        const camZ = Math.cos(followAzRad) * dist;

        this.desiredPos.set(camX, camY, camZ);
        this.desiredTarget.set(0, targetY, 0);

        const alpha = 1 - Math.exp(-Math.min(0.1, Math.max(0.001, delta)) * 12);
        camera.position.lerp(this.desiredPos, alpha);
        this.currentTarget.lerp(this.desiredTarget, alpha);
        camera.lookAt(this.currentTarget);
      } else {
        const controls = this.controlsRef?.nativeElement;
        if (controls?.enabled) {
          controls.target.set(0, ORBIT_TARGET_Y, 0);
          controls.update();
        }
      }
    });
  }

  onOrbitChange(): void {
    if (this.isInternalControlUpdate || this.cameraMode() !== 'orbit') {
      return;
    }
    const controls = this.controlsRef?.nativeElement;
    if (!controls) {
      return;
    }
    const azRad = controls.getAzimuthalAngle();
    const azDeg = (((azRad * 180) / Math.PI) % 360 + 360) % 360;
    this.lastAppliedAzimuthDeg = azDeg;
    this.cameraAzimuthChanged.emit(azDeg);
  }

  private applyOrbitCameraPose(
    camera: Vector3 | { position: Vector3; lookAt: (v: Vector3) => void },
    azimuthDeg: number,
  ): void {
    if (!('position' in camera)) {
      return;
    }
    this.isInternalControlUpdate = true;
    try {
      const azRad = (azimuthDeg * Math.PI) / 180;
      const polarRad = (78 * Math.PI) / 180;
      const sinPolar = Math.sin(polarRad);
      camera.position.set(
        ORBIT_INITIAL_DISTANCE * sinPolar * Math.sin(azRad),
        ORBIT_TARGET_Y + ORBIT_INITIAL_DISTANCE * Math.cos(polarRad),
        ORBIT_INITIAL_DISTANCE * sinPolar * Math.cos(azRad),
      );
      this.desiredTarget.set(0, ORBIT_TARGET_Y, 0);
      camera.lookAt(this.desiredTarget);
      const controls = this.controlsRef?.nativeElement;
      if (controls) {
        controls.target.copy(this.desiredTarget);
        controls.update();
      }
    } finally {
      this.isInternalControlUpdate = false;
    }
  }
}
