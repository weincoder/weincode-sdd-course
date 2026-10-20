import {
  CUSTOM_ELEMENTS_SCHEMA,
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  computed,
  effect,
  inject,
  input,
  output,
} from '@angular/core';
import { NgtArgs } from 'angular-three';
import {
  BufferAttribute,
  Color,
  ConeGeometry,
  DataTexture,
  DodecahedronGeometry,
  Euler,
  InstancedMesh,
  LinearFilter,
  Matrix4,
  MeshStandardMaterial,
  PlaneGeometry,
  Quaternion,
  RGBAFormat,
  RepeatWrapping,
  TorusGeometry,
  Vector3,
} from 'three';
import { TerrainTheme } from '../../../../domain/models/celestial-body/celestial-body';
import {
  TerrainFeature,
  TerrainFeatureKind,
  TerrainLayout,
} from '../../../../domain/models/scene/terrain-layout';
import { QualitySettings } from './scene-descriptor.mapper';

interface FeatureGroupBinding {
  readonly kind: TerrainFeatureKind;
  readonly mesh: InstancedMesh;
}

@Component({
  selector: 'app-terrain-mesh',
  imports: [NgtArgs],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <ngt-group>
      @if (surfaceGeometry(); as geom) {
        <ngt-mesh [geometry]="geom" [receiveShadow]="true" [castShadow]="true">
          <ngt-mesh-standard-material
            [vertexColors]="true"
            [map]="detailTexture()"
            [bumpMap]="detailTexture()"
            [bumpScale]="0.32"
            [roughness]="0.86"
            [metalness]="0.08"
          />
        </ngt-mesh>
      }

      <!-- Reinforced Landing Pad Outer Rim Ring -->
      <ngt-mesh
        [position]="[0, 0.06, 0]"
        [rotation]="[-1.5707963, 0, 0]"
        [receiveShadow]="true"
        [castShadow]="true"
      >
        <ngt-torus-geometry *args="[terrain().padRadiusMeters - 0.15, 0.14, 10, 48]" />
        <ngt-mesh-standard-material
          [color]="theme().landingPadTrimHex"
          [roughness]="0.42"
          [metalness]="0.55"
        />
      </ngt-mesh>

      <!-- 4 Perimeter Landing Beacon Lights around the Pad -->
      @for (beaconPos of padBeaconPositions(); track $index) {
        <ngt-group [position]="beaconPos">
          <ngt-mesh [position]="[0, 0.18, 0]" [castShadow]="true">
            <ngt-cylinder-geometry *args="[0.12, 0.16, 0.36, 10]" />
            <ngt-mesh-standard-material
              [color]="theme().landingPadTrimHex"
              [roughness]="0.38"
              [metalness]="0.62"
            />
          </ngt-mesh>
          <ngt-mesh [position]="[0, 0.42, 0]">
            <ngt-sphere-geometry *args="[0.11, 10, 10]" />
            <ngt-mesh-basic-material [color]="theme().accentFeatureColorHex" />
          </ngt-mesh>
        </ngt-group>
      }

      @for (group of featureMeshes(); track group.kind) {
        <ngt-primitive *args="[group.mesh]" />
      }

      <!-- Reference vertical post (2.0 m height, radius 0.08 m) at (padRadius + 1.5, 0, 0) for V4 shadow-length verification -->
      <ngt-group [position]="referencePostBasePosition()">
        <ngt-mesh [position]="[0, 0.05, 0]" [receiveShadow]="true" [castShadow]="true">
          <ngt-cylinder-geometry *args="[0.32, 0.38, 0.1, 16]" />
          <ngt-mesh-standard-material
            [color]="theme().landingPadColorHex"
            [roughness]="0.5"
            [metalness]="0.45"
          />
        </ngt-mesh>
        <ngt-mesh [position]="[0, 1.0, 0]" [castShadow]="true" [receiveShadow]="true">
          <ngt-cylinder-geometry *args="[0.08, 0.08, 2.0, 14]" />
          <ngt-mesh-standard-material
            [color]="theme().landingPadTrimHex"
            [roughness]="0.42"
            [metalness]="0.4"
          />
        </ngt-mesh>
      </ngt-group>
    </ngt-group>
  `,
})
export class TerrainMeshComponent {
  readonly terrain = input.required<TerrainLayout>();
  readonly theme = input.required<TerrainTheme>();
  readonly quality = input.required<QualitySettings>();

  readonly terrainReady = output<void>();

  private readonly destroyRef = inject(DestroyRef);
  private previousGeometry: PlaneGeometry | null = null;
  private previousInstancedMeshes: InstancedMesh[] = [];
  private previousDetailTexture: DataTexture | null = null;
  private hasEmittedReady = false;

  readonly referencePostBasePosition = computed<[number, number, number]>(() => [
    this.terrain().padRadiusMeters + 1.5,
    0,
    0,
  ]);

  readonly padBeaconPositions = computed<readonly [number, number, number][]>(() => {
    const r = this.terrain().padRadiusMeters - 0.15;
    return [
      [r, 0, 0],
      [-r, 0, 0],
      [0, 0, r],
      [0, 0, -r],
    ];
  });

  readonly detailTexture = computed<DataTexture>(() => {
    // Re-key on theme kind so each planet gets a freshly bound surface grain texture
    this.theme();
    if (this.previousDetailTexture) {
      this.previousDetailTexture.dispose();
    }

    const size = 128;
    const data = new Uint8Array(size * size * 4);
    for (let y = 0; y < size; y++) {
      for (let x = 0; x < size; x++) {
        const idx = (y * size + x) * 4;
        const h1 = ((Math.imul(x * 73856093 ^ y * 19349663, 1274126177) >>> 16) & 0xff) / 255;
        const h2 = Math.sin(x * 0.35 + y * 0.22) * 0.5 + 0.5;
        const ripple = Math.cos(x * 0.18 - y * 0.48) * 0.5 + 0.5;
        const v = Math.round((0.72 + h1 * 0.18 + h2 * 0.06 + ripple * 0.04) * 235);
        data[idx] = v;
        data[idx + 1] = v;
        data[idx + 2] = v;
        data[idx + 3] = 255;
      }
    }

    const tex = new DataTexture(data, size, size, RGBAFormat);
    tex.wrapS = RepeatWrapping;
    tex.wrapT = RepeatWrapping;
    tex.magFilter = LinearFilter;
    tex.minFilter = LinearFilter;
    tex.repeat.set(36, 36);
    tex.needsUpdate = true;
    this.previousDetailTexture = tex;
    return tex;
  });

  readonly surfaceGeometry = computed<PlaneGeometry>(() => {
    const layout = this.terrain();
    const terrainTheme = this.theme();
    const res = layout.resolution;
    const extent = layout.sizeMeters;

    if (this.previousGeometry) {
      this.previousGeometry.dispose();
    }

    const geometry = new PlaneGeometry(extent, extent, res - 1, res - 1);
    geometry.rotateX(-Math.PI / 2);

    const posAttr = geometry.attributes['position'];
    const vertexCount = posAttr.count;
    const colors = new Float32Array(vertexCount * 3);

    const primaryColor = new Color(terrainTheme.primarySurfaceHex);
    const secondaryColor = new Color(terrainTheme.secondarySurfaceHex);
    const featureColor = new Color(terrainTheme.featureColorHex);
    const accentColor = new Color(terrainTheme.accentFeatureColorHex);
    const padColor = new Color(terrainTheme.landingPadColorHex);
    const trimColor = new Color(terrainTheme.landingPadTrimHex);
    const scorchColor = new Color(terrainTheme.landingPadColorHex).multiplyScalar(0.55);
    const scratch = new Color();

    for (let i = 0; i < vertexCount; i++) {
      const h = layout.heights[i] ?? 0;
      posAttr.setY(i, h);

      const vx = posAttr.getX(i);
      const vz = posAttr.getZ(i);
      const r = Math.hypot(vx, vz);

      if (r <= 1.8) {
        // Inner rocket exhaust scorch zone on pad
        const t = r / 1.8;
        scratch.copy(scorchColor).lerp(padColor, t);
      } else if (r <= layout.padRadiusMeters - 0.55) {
        const isCrosshair = Math.abs(vx) < 0.28 || Math.abs(vz) < 0.28;
        const isInnerRing = Math.abs(r - layout.padRadiusMeters * 0.55) < 0.25;
        if (isCrosshair || isInnerRing) {
          scratch.copy(trimColor);
        } else {
          scratch.copy(padColor);
        }
      } else if (r <= layout.padRadiusMeters + 0.35) {
        scratch.copy(trimColor);
      } else {
        // Multi-band geological coloration across plains, slopes, and ridges
        const micro =
          Math.sin(vx * 0.14 + vz * 0.11) * 0.5 +
          Math.cos(vx * 0.05 - vz * 0.07) * 0.5;
        const heightRatio = Math.min(1, Math.max(0, (h + 0.8) / (layout.maxHeightMeters * 0.75)));
        if (heightRatio < 0.45) {
          const t = Math.min(1, Math.max(0, heightRatio / 0.45 + micro * 0.14));
          scratch.copy(primaryColor).lerp(secondaryColor, t);
        } else {
          const t = Math.min(1, Math.max(0, (heightRatio - 0.45) / 0.55 + micro * 0.12));
          scratch.copy(secondaryColor).lerp(featureColor, t * 0.75).lerp(accentColor, t * 0.25);
        }
      }

      colors[i * 3] = scratch.r;
      colors[i * 3 + 1] = scratch.g;
      colors[i * 3 + 2] = scratch.b;
    }

    geometry.setAttribute('color', new BufferAttribute(colors, 3));
    posAttr.needsUpdate = true;
    geometry.computeVertexNormals();
    this.previousGeometry = geometry;
    return geometry;
  });

  readonly featureMeshes = computed<readonly FeatureGroupBinding[]>(() => {
    const layout = this.terrain();
    const terrainTheme = this.theme();

    for (const old of this.previousInstancedMeshes) {
      old.geometry.dispose();
      if (Array.isArray(old.material)) {
        old.material.forEach((m) => m.dispose());
      } else {
        old.material.dispose();
      }
    }
    this.previousInstancedMeshes = [];

    const byKind = new Map<TerrainFeatureKind, TerrainFeature[]>();
    for (const f of layout.features) {
      const list = byKind.get(f.kind) ?? [];
      list.push(f);
      byKind.set(f.kind, list);
    }

    const result: FeatureGroupBinding[] = [];
    const matrix = new Matrix4();
    const pos = new Vector3();
    const quat = new Quaternion();
    const scale = new Vector3();
    const euler = new Euler();

    for (const [kind, items] of byKind.entries()) {
      if (items.length === 0) {
        continue;
      }
      const geom = this.createFeatureGeometry(kind);
      const colorHex =
        kind === 'vegetation' || kind === 'dune'
          ? terrainTheme.accentFeatureColorHex
          : terrainTheme.featureColorHex;
      const mat = new MeshStandardMaterial({
        color: new Color(colorHex),
        roughness: kind === 'iceRidge' ? 0.45 : 0.84,
        metalness: kind === 'iceRidge' ? 0.25 : 0.1,
      });

      const instanced = new InstancedMesh(geom, mat, items.length);
      instanced.castShadow = true;
      instanced.receiveShadow = true;

      for (let i = 0; i < items.length; i++) {
        const item = items[i];
        const surfaceY = this.sampleHeight(layout, item.x, item.z);
        const yOffset = kind === 'crater' ? 0.08 : item.height * 0.38;
        pos.set(item.x, surfaceY + yOffset, item.z);
        euler.set(0, item.rotationRad, 0);
        quat.setFromEuler(euler);
        if (kind === 'dune') {
          scale.set(item.radius * 1.6, item.height * 0.45, item.radius * 0.85);
        } else {
          scale.set(item.radius, item.height, item.radius);
        }
        matrix.compose(pos, quat, scale);
        instanced.setMatrixAt(i, matrix);
      }
      instanced.instanceMatrix.needsUpdate = true;
      this.previousInstancedMeshes.push(instanced);
      result.push({ kind, mesh: instanced });
    }

    return result;
  });

  constructor() {
    effect(() => {
      this.surfaceGeometry();
      this.featureMeshes();
      if (!this.hasEmittedReady) {
        this.hasEmittedReady = true;
        this.terrainReady.emit();
      }
    });

    this.destroyRef.onDestroy(() => {
      this.previousGeometry?.dispose();
      this.previousDetailTexture?.dispose();
      for (const mesh of this.previousInstancedMeshes) {
        mesh.geometry.dispose();
      }
    });
  }

  private createFeatureGeometry(kind: TerrainFeatureKind) {
    switch (kind) {
      case 'crater': {
        const torus = new TorusGeometry(1.0, 0.24, 10, 24);
        torus.rotateX(Math.PI / 2);
        return torus;
      }
      case 'vegetation':
        return new ConeGeometry(0.68, 2.1, 8);
      case 'iceRidge':
        return new ConeGeometry(0.95, 1.5, 6);
      case 'dune':
        return new DodecahedronGeometry(0.9, 1);
      case 'rock':
      default:
        return new DodecahedronGeometry(0.78, 1);
    }
  }

  private sampleHeight(layout: TerrainLayout, x: number, z: number): number {
    const res = layout.resolution;
    const half = layout.sizeMeters / 2;
    const gx = Math.min(
      res - 1,
      Math.max(0, Math.round(((x + half) / layout.sizeMeters) * (res - 1))),
    );
    const gz = Math.min(
      res - 1,
      Math.max(0, Math.round(((z + half) / layout.sizeMeters) * (res - 1))),
    );
    return layout.heights[gz * res + gx] ?? 0;
  }
}
