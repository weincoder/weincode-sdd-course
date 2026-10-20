import {
  CUSTOM_ELEMENTS_SCHEMA,
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  ViewChild,
  computed,
  effect,
  inject,
  input,
} from '@angular/core';
import { NgtArgs, injectStore } from 'angular-three';
import {
  BackSide,
  BufferAttribute,
  BufferGeometry,
  Color,
  DirectionalLight,
  DoubleSide,
  PCFShadowMap,
  PCFSoftShadowMap,
  SphereGeometry,
  Uint16BufferAttribute,
} from 'three';
import {
  CelestialBodyId,
  SkyOpticalProfile,
} from '../../../../domain/models/celestial-body/celestial-body';
import { SceneLightingState } from '../../../../domain/models/scene/scene-lighting-state';
import { QualitySettings } from './scene-descriptor.mapper';

const SUN_DISTANCE_METERS = 360;
const SKY_DOME_RADIUS_METERS = 520;
const STARFIELD_RADIUS_METERS = 390;
const COMPANION_DISTANCE_METERS = 270;

type CompanionKind = 'moon' | 'earth' | 'jupiter';

@Component({
  selector: 'app-sun-light',
  imports: [NgtArgs],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <ngt-directional-light
      #dirLight
      [position]="sunPosition()"
      [color]="activeLightColorHex()"
      [intensity]="activeLightIntensity()"
      [visible]="activeLightIntensity() > 0"
      [castShadow]="lighting().castsShadows"
    />

    <ngt-hemisphere-light
      [color]="lighting().ambientSkyColorHex"
      [groundColor]="lighting().ambientGroundColorHex"
      [intensity]="hemisphereIntensity()"
    />

    <!-- 3D Gradient Sky Dome surrounding the scene -->
    @if (skyDomeGeometry(); as domeGeom) {
      <ngt-mesh [position]="[0, clampedAltitude(), 0]" [geometry]="domeGeom">
        <ngt-mesh-basic-material
          [vertexColors]="true"
          [side]="backSide"
          [depthWrite]="false"
          [fog]="false"
        />
      </ngt-mesh>
    }

    <!-- 3D Nocturnal / Airless Starfield (3D Diamond Star Mesh + Point Sparkles) -->
    @if (starfieldVisibility() > 0.01) {
      <ngt-group [position]="[0, clampedAltitude(), 0]">
        <ngt-mesh [geometry]="starfieldMeshGeometry">
          <ngt-mesh-basic-material
            [vertexColors]="true"
            [side]="doubleSide"
            [transparent]="true"
            [opacity]="starfieldVisibility()"
            [depthWrite]="false"
            [fog]="false"
          />
        </ngt-mesh>

        <ngt-points [geometry]="starfieldPointsGeometry">
          <ngt-points-material
            [vertexColors]="true"
            [size]="4.2"
            [sizeAttenuation]="false"
            [transparent]="true"
            [opacity]="starfieldVisibility()"
            [depthWrite]="false"
            [fog]="false"
          />
        </ngt-points>
      </ngt-group>
    }

    <!-- Companion Celestial Body: Moon on Earth (night), Earth on Moon, Jupiter on Titan -->
    @if (companionOpacity() > 0.01 && companionGeometry(); as compGeom) {
      <ngt-group [position]="companionPosition()">
        <ngt-mesh [geometry]="compGeom" [rotation]="companionRotation()">
          <ngt-mesh-basic-material
            [vertexColors]="true"
            [transparent]="true"
            [opacity]="companionOpacity()"
            [fog]="false"
          />
        </ngt-mesh>

        <!-- Outer Atmospheric / Corona Limb Glow -->
        @if (companionHaloGeometry(); as haloGeom) {
          <ngt-mesh [geometry]="haloGeom">
            <ngt-mesh-basic-material
              [color]="companionHaloColor()"
              [transparent]="true"
              [opacity]="companionHaloOpacity()"
              [depthWrite]="false"
              [fog]="false"
            />
          </ngt-mesh>
        }
      </ngt-group>
    }

    <!-- Visible 3D Sun Disc + Atmospheric Corona Halo -->
    @if (isSunAboveTwilight()) {
      <ngt-group [position]="sunVisualPosition()">
        <!-- Bright Solar Photosphere Disc -->
        <ngt-mesh>
          <ngt-sphere-geometry *args="[13.5, 28, 28]" />
          <ngt-mesh-basic-material
            [color]="sunDiscColor()"
            [fog]="false"
          />
        </ngt-mesh>

        <!-- Inner Solar Corona -->
        <ngt-mesh>
          <ngt-sphere-geometry *args="[25.0, 24, 24]" />
          <ngt-mesh-basic-material
            [color]="sunHaloColor()"
            [transparent]="true"
            [opacity]="innerHaloOpacity()"
            [depthWrite]="false"
            [fog]="false"
          />
        </ngt-mesh>

        <!-- Outer Atmospheric Scattering Halo (Orange on Earth, Blue on Mars, Amber on Titan, 0 on Moon) -->
        @if (outerHaloOpacity() > 0.01) {
          <ngt-mesh>
            <ngt-sphere-geometry *args="[54.0, 24, 24]" />
            <ngt-mesh-basic-material
              [color]="sunHaloColor()"
              [transparent]="true"
              [opacity]="outerHaloOpacity()"
              [depthWrite]="false"
              [fog]="false"
            />
          </ngt-mesh>
        }
      </ngt-group>
    }

    @if (showAtmosphericHaze()) {
      <ngt-fog-exp2 *args="[horizonColorHex(), 0.0011]" attach="fog" />
    }
  `,
})
export class SunLightComponent {
  @ViewChild('dirLight')
  private readonly dirLightRef?: ElementRef<DirectionalLight>;

  readonly lighting = input.required<SceneLightingState>();
  readonly quality = input.required<QualitySettings>();
  readonly landerAltitude = input<number>(0);
  readonly hasAtmosphere = input<boolean>(true);
  readonly skyProfile = input<SkyOpticalProfile | null>(null);
  readonly worldId = input<CelestialBodyId>('earth');

  readonly backSide = BackSide;
  readonly doubleSide = DoubleSide;
  readonly starfieldPointsGeometry = this.buildStarfieldPointsGeometry();
  readonly starfieldMeshGeometry = this.buildStarfieldMeshGeometry();

  private readonly store = injectStore();
  private readonly destroyRef = inject(DestroyRef);
  private previousDomeGeometry: SphereGeometry | null = null;
  private previousCompanionGeometry: SphereGeometry | null = null;
  private previousCompanionHaloGeometry: SphereGeometry | null = null;
  private lastShadowMapSize = 0;

  readonly clampedAltitude = computed<number>(() => Math.max(0, this.landerAltitude()));

  readonly isEarthNightWithMoonlight = computed<boolean>(
    () =>
      this.worldId() === 'earth' &&
      this.lighting().solarElevationDeg <= 0.5 &&
      this.lighting().sunIntensity < 0.08,
  );

  readonly activeLightColorHex = computed<string>(() =>
    this.isEarthNightWithMoonlight() ? '#9EC2FF' : this.lighting().sunColorHex,
  );

  readonly activeLightIntensity = computed<number>(() =>
    this.isEarthNightWithMoonlight() ? 0.55 : this.lighting().sunIntensity * 2.4,
  );

  readonly isSunAboveTwilight = computed<boolean>(
    () => this.lighting().solarElevationDeg >= -6 && this.lighting().sunIntensity > 0.01,
  );

  readonly starfieldVisibility = computed<number>(() => {
    const elev = this.lighting().solarElevationDeg;
    if (this.worldId() === 'moon') {
      return elev > 15 ? 0.85 : 1.0;
    }
    return Math.max(0, Math.min(1, (18 - elev) / 20));
  });

  readonly companionKind = computed<CompanionKind | null>(() => {
    const w = this.worldId();
    if (w === 'earth') {
      return 'moon';
    }
    if (w === 'moon') {
      return 'earth';
    }
    if (w === 'titan') {
      return 'jupiter';
    }
    return null;
  });

  readonly companionOpacity = computed<number>(() => {
    const kind = this.companionKind();
    if (!kind) {
      return 0;
    }
    if (kind === 'moon') {
      const elev = this.lighting().solarElevationDeg;
      return Math.max(0, Math.min(1, (22 - elev) / 24));
    }
    return 1.0;
  });

  readonly companionPosition = computed<[number, number, number]>(() => {
    const alt = this.clampedAltitude();
    const azRad = (235 * Math.PI) / 180;
    const elRad = (12.5 * Math.PI) / 180;
    const cosE = Math.cos(elRad);
    return [
      Math.sin(azRad) * cosE * COMPANION_DISTANCE_METERS,
      alt + Math.sin(elRad) * COMPANION_DISTANCE_METERS,
      Math.cos(azRad) * cosE * COMPANION_DISTANCE_METERS,
    ];
  });

  readonly companionRotation = computed<[number, number, number]>(() => {
    const kind = this.companionKind();
    if (kind === 'jupiter') {
      return [0.08, -0.45, -0.14];
    }
    if (kind === 'earth') {
      return [0.22, -0.6, 0.18];
    }
    return [0.1, -0.35, 0.06];
  });

  readonly companionGeometry = computed<SphereGeometry | null>(() => {
    const kind = this.companionKind();
    if (this.previousCompanionGeometry) {
      this.previousCompanionGeometry.dispose();
      this.previousCompanionGeometry = null;
    }
    if (!kind) {
      return null;
    }
    const radius = kind === 'jupiter' ? 21.5 : kind === 'earth' ? 16.5 : 12.0;
    const geom = this.buildCompanionSphereGeometry(radius, kind);
    this.previousCompanionGeometry = geom;
    return geom;
  });

  readonly companionHaloGeometry = computed<SphereGeometry | null>(() => {
    const kind = this.companionKind();
    if (this.previousCompanionHaloGeometry) {
      this.previousCompanionHaloGeometry.dispose();
      this.previousCompanionHaloGeometry = null;
    }
    if (!kind) {
      return null;
    }
    const haloRadius =
      kind === 'jupiter' ? 21.5 * 1.18 : kind === 'earth' ? 16.5 * 1.2 : 12.0 * 1.32;
    const geom = new SphereGeometry(haloRadius, 24, 18);
    this.previousCompanionHaloGeometry = geom;
    return geom;
  });

  readonly companionHaloColor = computed<string>(() => {
    const kind = this.companionKind();
    if (kind === 'earth') {
      return '#4DA6FF';
    }
    if (kind === 'jupiter') {
      return '#E8A050';
    }
    return '#C8DCFF';
  });

  readonly companionHaloOpacity = computed<number>(() => {
    const kind = this.companionKind();
    const base = kind === 'earth' ? 0.24 : kind === 'jupiter' ? 0.16 : 0.22;
    return base * this.companionOpacity();
  });

  readonly sunPosition = computed<[number, number, number]>(() => {
    const dir = this.lighting().sunDirection;
    const alt = this.clampedAltitude();
    return [
      dir.x * SUN_DISTANCE_METERS,
      alt + dir.y * SUN_DISTANCE_METERS,
      dir.z * SUN_DISTANCE_METERS,
    ];
  });

  readonly sunVisualPosition = computed<[number, number, number]>(() => {
    const dir = this.lighting().sunDirection;
    const elev = this.lighting().solarElevationDeg;
    const alt = this.clampedAltitude();
    const horizLen = Math.sqrt(dir.x * dir.x + dir.z * dir.z);
    const dirX = horizLen > 1e-5 ? dir.x / horizLen : -0.9397;
    const dirZ = horizLen > 1e-5 ? dir.z / horizLen : -0.342;
    const visualElevDeg =
      elev >= 0 ? 1.5 + 15.0 * Math.pow(elev / 90.0, 0.72) : elev * 0.8;
    const visualRad = (visualElevDeg * Math.PI) / 180;
    const cosV = Math.cos(visualRad);
    return [
      dirX * cosV * SUN_DISTANCE_METERS,
      alt + Math.sin(visualRad) * SUN_DISTANCE_METERS,
      dirZ * cosV * SUN_DISTANCE_METERS,
    ];
  });

  readonly activeKeyframeColors = computed(() => {
    const profile = this.skyProfile();
    const elev = this.lighting().solarElevationDeg;
    const fallback = {
      zenith: this.lighting().ambientSkyColorHex,
      horizon: this.lighting().sunColorHex,
      halo: this.lighting().sunColorHex,
      disc: this.lighting().sunColorHex,
    };
    if (!profile || profile.keyframes.length === 0) {
      return fallback;
    }

    const kf = profile.keyframes;
    if (elev <= kf[0].elevationDeg) {
      return {
        zenith: kf[0].zenithColorHex,
        horizon: kf[0].horizonColorHex,
        halo: kf[0].sunHaloColorHex,
        disc: kf[0].sunDiscColorHex,
      };
    }

    for (let i = 0; i < kf.length - 1; i++) {
      const a = kf[i];
      const b = kf[i + 1];
      if (elev >= a.elevationDeg && elev <= b.elevationDeg) {
        const t =
          b.elevationDeg > a.elevationDeg
            ? (elev - a.elevationDeg) / (b.elevationDeg - a.elevationDeg)
            : 0;
        const lerpHex = (c1: string, c2: string) =>
          `#${new Color(c1).lerp(new Color(c2), t).getHexString().toUpperCase()}`;
        return {
          zenith: lerpHex(a.zenithColorHex, b.zenithColorHex),
          horizon: lerpHex(a.horizonColorHex, b.horizonColorHex),
          halo: lerpHex(a.sunHaloColorHex, b.sunHaloColorHex),
          disc: lerpHex(a.sunDiscColorHex, b.sunDiscColorHex),
        };
      }
    }

    const last = kf[kf.length - 1];
    return {
      zenith: last.zenithColorHex,
      horizon: last.horizonColorHex,
      halo: last.sunHaloColorHex,
      disc: last.sunDiscColorHex,
    };
  });

  readonly horizonColorHex = computed<string>(() => this.activeKeyframeColors().horizon);
  readonly sunHaloColor = computed<string>(() => this.activeKeyframeColors().halo);
  readonly sunDiscColor = computed<string>(() => this.activeKeyframeColors().disc);

  readonly innerHaloOpacity = computed<number>(() =>
    this.hasAtmosphere() ? 0.45 : 0.16,
  );

  readonly outerHaloOpacity = computed<number>(() => {
    if (!this.hasAtmosphere()) {
      return 0;
    }
    const lowSunBoost = Math.max(0, Math.min(1, (25 - this.lighting().solarElevationDeg) / 25));
    return 0.18 + lowSunBoost * 0.28;
  });

  readonly skyDomeGeometry = computed<SphereGeometry>(() => {
    const colorsState = this.activeKeyframeColors();
    const groundHex = this.lighting().ambientGroundColorHex;

    if (this.previousDomeGeometry) {
      this.previousDomeGeometry.dispose();
    }

    const geom = new SphereGeometry(SKY_DOME_RADIUS_METERS, 32, 20);
    const pos = geom.attributes['position'];
    const count = pos.count;
    const colors = new Float32Array(count * 3);

    const zenithCol = new Color(colorsState.zenith);
    const horizonCol = new Color(colorsState.horizon);
    const groundCol = new Color(groundHex).multiplyScalar(0.35);
    const scratch = new Color();

    for (let i = 0; i < count; i++) {
      const ny = pos.getY(i) / SKY_DOME_RADIUS_METERS;
      if (ny >= 0) {
        const t = Math.pow(ny, 0.55);
        scratch.copy(horizonCol).lerp(zenithCol, t);
      } else {
        const t = Math.min(1, Math.abs(ny) * 3.0);
        scratch.copy(horizonCol).lerp(groundCol, t);
      }
      colors[i * 3] = scratch.r;
      colors[i * 3 + 1] = scratch.g;
      colors[i * 3 + 2] = scratch.b;
    }

    geom.setAttribute('color', new BufferAttribute(colors, 3));
    this.previousDomeGeometry = geom;
    return geom;
  });

  readonly hemisphereIntensity = computed<number>(() => {
    const state = this.lighting();
    if (state.shadowSoftness <= 0) {
      return 0;
    }
    return state.ambientIntensity * 1.35;
  });

  readonly showAtmosphericHaze = computed<boolean>(
    () => this.quality().atmosphericHazeEnabled && this.hasAtmosphere(),
  );

  constructor() {
    effect(() => {
      const light = this.dirLightRef?.nativeElement;
      const state = this.lighting();
      const qual = this.quality();
      const altitude = this.clampedAltitude();
      const gl = this.store.snapshot.gl;

      if (gl?.shadowMap) {
        const nextType =
          qual.softShadows && state.shadowSoftness > 0 ? PCFSoftShadowMap : PCFShadowMap;
        if (gl.shadowMap.type !== nextType) {
          gl.shadowMap.type = nextType;
          gl.shadowMap.needsUpdate = true;
        }
      }

      if (!light) {
        return;
      }

      light.target.position.set(0, altitude, 0);
      light.target.updateMatrixWorld();

      if (this.lastShadowMapSize !== qual.shadowMapSize) {
        light.shadow.mapSize.set(qual.shadowMapSize, qual.shadowMapSize);
        if (light.shadow.map) {
          light.shadow.map.dispose();
          light.shadow.map = null;
        }
        this.lastShadowMapSize = qual.shadowMapSize;
      }

      light.shadow.radius = qual.softShadows ? Math.max(1, state.shadowSoftness * 6) : 1;
      light.shadow.bias = -0.0005;

      const clampedElevDeg = Math.max(state.solarElevationDeg, 5);
      const tanE = Math.tan((clampedElevDeg * Math.PI) / 180);
      const halfExtent = Math.max(40, (6 * 3) / tanE);
      const cam = light.shadow.camera;
      cam.left = -halfExtent;
      cam.right = halfExtent;
      cam.top = halfExtent;
      cam.bottom = -halfExtent;
      cam.near = 1;
      cam.far = SUN_DISTANCE_METERS * 2.4;
      cam.updateProjectionMatrix();
    });

    this.destroyRef.onDestroy(() => {
      this.previousDomeGeometry?.dispose();
      this.previousCompanionGeometry?.dispose();
      this.previousCompanionHaloGeometry?.dispose();
      this.starfieldPointsGeometry.dispose();
      this.starfieldMeshGeometry.dispose();
    });
  }

  private buildStarfieldPointsGeometry(): BufferGeometry {
    const starCount = 380;
    const positions = new Float32Array(starCount * 3);
    const colors = new Float32Array(starCount * 3);
    let seed = 0x51a7f1e1;
    const nextRand = () => {
      seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
      return seed / 0xffffffff;
    };

    for (let i = 0; i < starCount; i++) {
      let azDeg: number;
      let elevDeg: number;
      if (i < 210) {
        // Forward sky band visible in the camera's upper viewport
        azDeg = 175 + nextRand() * 150;
        elevDeg = 1.2 + nextRand() * 24;
      } else {
        // 360° sky dome for camera orbiting
        azDeg = nextRand() * 360;
        elevDeg = 1.5 + nextRand() * 65;
      }

      const azRad = (azDeg * Math.PI) / 180;
      const elRad = (elevDeg * Math.PI) / 180;
      const dist = STARFIELD_RADIUS_METERS - nextRand() * 20;

      positions[i * 3] = Math.sin(azRad) * Math.cos(elRad) * dist;
      positions[i * 3 + 1] = Math.sin(elRad) * dist;
      positions[i * 3 + 2] = Math.cos(azRad) * Math.cos(elRad) * dist;

      const spectrum = i % 5;
      let r = 0.96;
      let g = 0.98;
      let b = 1.0;
      if (spectrum === 0) {
        r = 0.8;
        g = 0.9;
        b = 1.0;
      } else if (spectrum === 1) {
        r = 1.0;
        g = 0.94;
        b = 0.78;
      } else if (spectrum === 2) {
        r = 1.0;
        g = 0.82;
        b = 0.64;
      }
      const brightness = 0.78 + 0.22 * nextRand();
      colors[i * 3] = r * brightness;
      colors[i * 3 + 1] = g * brightness;
      colors[i * 3 + 2] = b * brightness;
    }

    const geom = new BufferGeometry();
    geom.setAttribute('position', new BufferAttribute(positions, 3));
    geom.setAttribute('color', new BufferAttribute(colors, 3));
    return geom;
  }

  private buildStarfieldMeshGeometry(): BufferGeometry {
    const starCount = 280;
    const positions = new Float32Array(starCount * 4 * 3);
    const colors = new Float32Array(starCount * 4 * 3);
    const indices = new Uint16Array(starCount * 6);
    let seed = 0x73b91c45;
    const nextRand = () => {
      seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
      return seed / 0xffffffff;
    };

    for (let i = 0; i < starCount; i++) {
      let azDeg: number;
      let elevDeg: number;
      if (i < 165) {
        // Concentrate 60% of 3D diamond stars in the forward camera horizon band
        azDeg = 175 + nextRand() * 150;
        elevDeg = 1.2 + nextRand() * 24;
      } else {
        azDeg = nextRand() * 360;
        elevDeg = 1.5 + nextRand() * 65;
      }

      const azRad = (azDeg * Math.PI) / 180;
      const elRad = (elevDeg * Math.PI) / 180;
      const dist = STARFIELD_RADIUS_METERS - nextRand() * 25;

      const cx = Math.sin(azRad) * Math.cos(elRad) * dist;
      const cy = Math.sin(elRad) * dist;
      const cz = Math.cos(azRad) * Math.cos(elRad) * dist;

      const tx = Math.cos(azRad);
      const tz = -Math.sin(azRad);
      const size = i % 6 === 0 ? 2.4 : 1.15 + nextRand() * 0.95;

      const spectrum = i % 5;
      let r = 0.96;
      let g = 0.98;
      let b = 1.0;
      if (spectrum === 0) {
        r = 0.82;
        g = 0.91;
        b = 1.0;
      } else if (spectrum === 1) {
        r = 1.0;
        g = 0.94;
        b = 0.78;
      } else if (spectrum === 2) {
        r = 1.0;
        g = 0.82;
        b = 0.64;
      }
      const brightness = 0.82 + 0.18 * nextRand();
      r *= brightness;
      g *= brightness;
      b *= brightness;

      const vBase = i * 4;
      const pBase = vBase * 3;
      // Top
      positions[pBase] = cx;
      positions[pBase + 1] = cy + size;
      positions[pBase + 2] = cz;
      // Right
      positions[pBase + 3] = cx + tx * size;
      positions[pBase + 4] = cy;
      positions[pBase + 5] = cz + tz * size;
      // Bottom
      positions[pBase + 6] = cx;
      positions[pBase + 7] = cy - size;
      positions[pBase + 8] = cz;
      // Left
      positions[pBase + 9] = cx - tx * size;
      positions[pBase + 10] = cy;
      positions[pBase + 11] = cz - tz * size;

      for (let v = 0; v < 4; v++) {
        const cOff = (vBase + v) * 3;
        colors[cOff] = r;
        colors[cOff + 1] = g;
        colors[cOff + 2] = b;
      }

      const iBase = i * 6;
      indices[iBase] = vBase;
      indices[iBase + 1] = vBase + 1;
      indices[iBase + 2] = vBase + 2;
      indices[iBase + 3] = vBase;
      indices[iBase + 4] = vBase + 2;
      indices[iBase + 5] = vBase + 3;
    }

    const geom = new BufferGeometry();
    geom.setAttribute('position', new BufferAttribute(positions, 3));
    geom.setAttribute('color', new BufferAttribute(colors, 3));
    geom.setIndex(new Uint16BufferAttribute(indices, 1));
    return geom;
  }

  private buildCompanionSphereGeometry(radius: number, kind: CompanionKind): SphereGeometry {
    const geom = new SphereGeometry(radius, 36, 28);
    const pos = geom.attributes['position'];
    const count = pos.count;
    const colors = new Float32Array(count * 3);

    for (let i = 0; i < count; i++) {
      const nx = pos.getX(i) / radius;
      const ny = pos.getY(i) / radius;
      const nz = pos.getZ(i) / radius;

      let r = 0.85;
      let g = 0.88;
      let b = 0.94;

      if (kind === 'moon') {
        const mareNoise =
          Math.sin(nx * 3.1 + 0.6) * Math.cos(ny * 2.7 - 0.3) +
          0.5 * Math.sin(nz * 5.2 + nx * 2.4);
        const craterNoise = Math.sin(nx * 11.0) * Math.sin(ny * 11.0) * Math.sin(nz * 11.0);
        const mareFactor = Math.max(0, Math.min(1, (mareNoise + 0.15) * 0.85));
        r = 0.86 * (1 - mareFactor) + 0.32 * mareFactor + craterNoise * 0.06;
        g = 0.89 * (1 - mareFactor) + 0.35 * mareFactor + craterNoise * 0.06;
        b = 0.94 * (1 - mareFactor) + 0.42 * mareFactor + craterNoise * 0.06;
      } else if (kind === 'earth') {
        const absLat = Math.abs(ny);
        const contNoise =
          Math.sin(nx * 2.8 + 0.9) * Math.cos(ny * 2.2 - 0.4) +
          0.55 * Math.cos(nz * 3.4 - nx * 1.9);
        const cloudSwirl = Math.sin(nx * 5.5 + ny * 3.8 + nz * 4.2);

        if (absLat > 0.82) {
          r = 0.94;
          g = 0.97;
          b = 1.0;
        } else if (contNoise > 0.18) {
          const desert = Math.max(0, Math.min(1, (contNoise - 0.18) * 1.8));
          r = 0.18 * (1 - desert) + 0.68 * desert;
          g = 0.56 * (1 - desert) + 0.58 * desert;
          b = 0.24 * (1 - desert) + 0.32 * desert;
        } else {
          r = 0.06;
          g = 0.32;
          b = 0.78;
        }
        if (cloudSwirl > 0.38) {
          const c = Math.max(0, Math.min(0.85, (cloudSwirl - 0.38) * 1.4));
          r = r * (1 - c) + 0.98 * c;
          g = g * (1 - c) + 0.99 * c;
          b = b * (1 - c) + 1.0 * c;
        }
      } else {
        const bandWave = Math.sin(ny * 14.5 + 0.2 * Math.sin(nx * 4.0 + nz * 4.0));
        const fineBelt = Math.cos(ny * 29.0);
        if (bandWave > 0.25) {
          r = 0.95;
          g = 0.87;
          b = 0.72;
        } else if (bandWave > -0.25) {
          r = 0.82;
          g = 0.61;
          b = 0.4;
        } else {
          r = 0.64;
          g = 0.38;
          b = 0.24;
        }
        r += fineBelt * 0.04;
        g += fineBelt * 0.03;
        b += fineBelt * 0.02;

        const dLat = ny + 0.26;
        const dLon = nx - 0.42;
        const spotDist = dLat * dLat * 9.0 + dLon * dLon * 3.8;
        if (nz > -0.2 && spotDist < 0.22) {
          const spotFactor = Math.max(0, Math.min(1, 1 - spotDist / 0.22));
          r = r * (1 - spotFactor) + 0.86 * spotFactor;
          g = g * (1 - spotFactor) + 0.28 * spotFactor;
          b = b * (1 - spotFactor) + 0.16 * spotFactor;
        }
      }

      const sunLightDot = Math.max(0, Math.min(1, nx * 0.65 + ny * 0.45 + nz * 0.61));
      const shade = 0.28 + 0.72 * Math.pow(sunLightDot, 0.75);
      colors[i * 3] = Math.max(0, Math.min(1, r * shade));
      colors[i * 3 + 1] = Math.max(0, Math.min(1, g * shade));
      colors[i * 3 + 2] = Math.max(0, Math.min(1, b * shade));
    }

    geom.setAttribute('color', new BufferAttribute(colors, 3));
    return geom;
  }
}
