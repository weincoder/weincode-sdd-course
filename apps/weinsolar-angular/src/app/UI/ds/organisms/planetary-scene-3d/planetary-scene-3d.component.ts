import {
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  ElementRef,
   OnChanges,
  OnDestroy,
   ViewChild,
  input,
  output,
} from '@angular/core';
import { CelestialBody } from '../../../../domain/models/celestial-body/celestial-body';
import { LanderState } from '../../../../domain/models/simulation/lander-state';
import { SolarHourState } from '../../../../domain/models/simulation/solar-hour-state';

interface Vec3 {
  readonly x: number;
  readonly y: number;
  readonly z: number;
}

interface ProjectedPoint {
  readonly sx: number;
  readonly sy: number;
  readonly depth: number;
  readonly visible: boolean;
}

interface TerrainProp {
  readonly x: number;
  readonly z: number;
  readonly radius: number;
  readonly height: number;
  readonly kind: 'rock' | 'tree' | 'crater' | 'ice-spire';
}

@Component({
  selector: 'app-planetary-scene-3d',
  changeDetection: ChangeDetectionStrategy.OnPush,
  styles: [
    `
      :host {
        display: block;
        width: 100%;
        height: 100%;
      }
      .scene-canvas {
        display: block;
        width: 100%;
        height: 100%;
        cursor: grab;
      }
      .scene-canvas:active {
        cursor: grabbing;
      }
    `,
  ],
  template: `
    <canvas
      #sceneCanvas
      class="scene-canvas"
      data-testid="planetary-scene-canvas"
      (pointerdown)="onPointerDown($event)"
      (pointermove)="onPointerMove($event)"
      (pointerup)="onPointerUp()"
      (pointerleave)="onPointerUp()"
    ></canvas>
  `,
})
export class PlanetaryScene3dComponent implements AfterViewInit, OnChanges, OnDestroy {
  @ViewChild('sceneCanvas', { static: true })
  private readonly canvasRef!: ElementRef<HTMLCanvasElement>;

  readonly world = input.required<CelestialBody>();
  readonly landerState = input.required<LanderState>();
  readonly solarHourState = input.required<SolarHourState>();

  readonly cameraAzimuthChanged = output<number>();

  private readonly terrainProps: readonly TerrainProp[] = this.generateDeterministicProps();
  private isDraggingOrbit = false;
  private lastPointerX = 0;
  private resizeObserver: ResizeObserver | null = null;

  ngAfterViewInit(): void {
    this.syncCanvasDimensions();
    if (typeof ResizeObserver !== 'undefined') {
      this.resizeObserver = new ResizeObserver(() => {
        this.syncCanvasDimensions();
        this.renderScene();
      });
      this.resizeObserver.observe(this.canvasRef.nativeElement);
    }
    this.renderScene();
  }

  ngOnChanges(): void {
    this.renderScene();
  }

  ngOnDestroy(): void {
    this.resizeObserver?.disconnect();
  }

  onPointerDown(event: PointerEvent): void {
    if (!this.solarHourState().isUnlocked) {
      return;
    }
    this.isDraggingOrbit = true;
    this.lastPointerX = event.clientX;
  }

  onPointerMove(event: PointerEvent): void {
    if (!this.isDraggingOrbit || !this.solarHourState().isUnlocked) {
      return;
    }
    const deltaX = event.clientX - this.lastPointerX;
    this.lastPointerX = event.clientX;
    const nextAzimuth = (this.solarHourState().cameraAzimuthDeg + deltaX * 0.45 + 360) % 360;
    this.cameraAzimuthChanged.emit(nextAzimuth);
  }

  onPointerUp(): void {
    this.isDraggingOrbit = false;
  }

  private syncCanvasDimensions(): void {
    const canvas = this.canvasRef?.nativeElement;
    if (!canvas) {
      return;
    }
    const width = canvas.clientWidth || 960;
    const height = canvas.clientHeight || 600;
    if (canvas.width !== width || canvas.height !== height) {
      canvas.width = width;
      canvas.height = height;
    }
  }

  private renderScene(): void {
    const canvas = this.canvasRef?.nativeElement;
    if (!canvas) {
      return;
    }
    const ctx = canvas.getContext('2d');
    if (!ctx) {
      return;
    }

    const width = canvas.width || 960;
    const height = canvas.height || 600;
    const world = this.world();
    const lander = this.landerState();
    const solar = this.solarHourState();

    // Camera parameters: third-person tracking during descent (FR-027), horizon orbit on landing (FR-029)
    const isLandedObservation = solar.isUnlocked && lander.status === 'landed';
    const azimuthRad = ((solar.cameraAzimuthDeg * Math.PI) / 180) * (isLandedObservation ? 1 : 0);
    const camDistance = isLandedObservation ? 26 : 38;
    const landerVisualY = lander.altitude * 0.22;
    const camHeight = isLandedObservation ? 6.5 : Math.max(12, landerVisualY + 14);
    const lookAtY = isLandedObservation ? 5.0 : Math.max(2, landerVisualY * 0.72);

    const camPos: Vec3 = {
      x: Math.sin(azimuthRad) * camDistance,
      y: camHeight,
      z: -Math.cos(azimuthRad) * camDistance,
    };
    const lookAt: Vec3 = { x: 0, y: lookAtY, z: 0 };

    // 1. Sky background & stars (FR-015, FR-030)
    const horizonScreenY = isLandedObservation ? height * 0.56 : height * 0.44;
    const skyGrad = ctx.createLinearGradient(0, 0, 0, horizonScreenY);
    skyGrad.addColorStop(0, solar.zenithColorHex);
    skyGrad.addColorStop(1, solar.horizonColorHex);
    ctx.fillStyle = skyGrad;
    ctx.fillRect(0, 0, width, horizonScreenY + 2);

    if (!world.skyOpticalProfile.hasAtmosphere || solar.solarElevationDeg < 8) {
      this.drawStarfield(ctx, width, horizonScreenY, world.skyOpticalProfile.hasAtmosphere ? 0.45 : 0.95);
    }

    // 2. Sun disc & circumsolar halo (Rayleigh / Martian blue halo / Titan diffuse glow / Lunar sharp sun)
    this.drawSunAndHalo(ctx, width, horizonScreenY, solar, world);

    // 3. 3D Ground plane and world-specific perimeter relief (FR-028, FR-030)
    const lightingFactor = this.computeSurfaceLightingFactor(solar);
    const groundGrad = ctx.createLinearGradient(0, horizonScreenY, 0, height);
    groundGrad.addColorStop(
      0,
      this.shadeHex(world.terrainTheme.secondarySurfaceHex, lightingFactor * 0.9),
    );
    groundGrad.addColorStop(
      1,
      this.shadeHex(world.terrainTheme.primarySurfaceHex, lightingFactor),
    );
    ctx.fillStyle = groundGrad;
    ctx.fillRect(0, horizonScreenY, width, height - horizonScreenY);

    // Perspective grid rings on terrain
    this.drawTerrainGridAndPad(ctx, width, height, camPos, lookAt, world, lightingFactor);

    // 4. Perimeter 3D props (rocks, craters, vegetation, ice spires) sorted back-to-front
    this.drawPerimeterProps(ctx, width, height, camPos, lookAt, world, solar, lightingFactor);

    // 5. Dynamic lander shadow on landing pad (FR-030)
    this.drawLanderShadow(ctx, width, height, camPos, lookAt, landerVisualY, solar);

    // 6. 3D Lander spacecraft (intact, descending with thruster plume, or crashed debris)
    this.drawLander3d(ctx, width, height, camPos, lookAt, landerVisualY, lander, lightingFactor);
  }

  private drawStarfield(
    ctx: CanvasRenderingContext2D,
    width: number,
    horizonY: number,
    opacity: number,
  ): void {
    ctx.save();
    ctx.fillStyle = `rgba(245, 243, 235, ${opacity.toFixed(2)})`;
    for (let i = 0; i < 48; i++) {
      const sx = ((i * 197) % 997) / 997 * width;
      const sy = ((i * 353) % 887) / 887 * (horizonY * 0.92);
      const size = i % 4 === 0 ? 2 : 1.2;
      ctx.fillRect(sx, sy, size, size);
    }
    ctx.restore();
  }

  private drawSunAndHalo(
    ctx: CanvasRenderingContext2D,
    width: number,
    horizonY: number,
    solar: SolarHourState,
    world: CelestialBody,
  ): void {
    const relAzimuth = ((solar.cameraAzimuthDeg + 180) % 360) - 180;
    const sunX = width * 0.5 - (relAzimuth / 180) * (width * 0.42);
    const normalizedElev = (solar.solarElevationDeg - -10) / 100;
    const sunY = horizonY - (solar.solarElevationDeg / 90) * (horizonY * 0.78);

    if (solar.solarElevationDeg < -4 && !world.skyOpticalProfile.hasAtmosphere) {
      return;
    }

    ctx.save();
    if (world.skyOpticalProfile.hasAtmosphere) {
      const haloRadius = world.id === 'titan' ? 140 : 95;
      const haloGrad = ctx.createRadialGradient(sunX, sunY, 4, sunX, sunY, haloRadius);
      haloGrad.addColorStop(0, solar.sunHaloColorHex);
      haloGrad.addColorStop(1, 'rgba(0, 0, 0, 0)');
      ctx.fillStyle = haloGrad;
      ctx.beginPath();
      ctx.arc(sunX, sunY, haloRadius, 0, Math.PI * 2);
      ctx.fill();
    }

    if (solar.solarElevationDeg >= -1.5 && normalizedElev >= 0) {
      const discRadius = world.id === 'titan' ? 18 : 13;
      ctx.fillStyle = solar.sunDiscColorHex;
      ctx.beginPath();
      ctx.arc(sunX, sunY, discRadius, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.restore();
  }

  private drawTerrainGridAndPad(
    ctx: CanvasRenderingContext2D,
    width: number,
    height: number,
    camPos: Vec3,
    lookAt: Vec3,
    world: CelestialBody,
    lightingFactor: number,
  ): void {
    ctx.save();
    ctx.strokeStyle = this.shadeHex(world.terrainTheme.secondarySurfaceHex, lightingFactor * 0.75);
    ctx.lineWidth = 1;

    for (const radius of [7, 14, 24, 38]) {
      ctx.beginPath();
      let started = false;
      for (let deg = 0; deg <= 360; deg += 15) {
        const rad = (deg * Math.PI) / 180;
        const p = this.projectPoint(
          { x: Math.cos(rad) * radius, y: 0, z: Math.sin(rad) * radius },
          camPos,
          lookAt,
          width,
          height,
        );
        if (p.visible) {
          if (!started) {
            ctx.moveTo(p.sx, p.sy);
            started = true;
          } else {
            ctx.lineTo(p.sx, p.sy);
          }
        }
      }
      ctx.stroke();
    }

    // Flat circular landing pad at origin (radius 5.5)
    ctx.fillStyle = this.shadeHex(world.terrainTheme.landingPadColorHex, lightingFactor);
    ctx.strokeStyle = this.shadeHex(world.terrainTheme.landingPadTrimHex, lightingFactor);
    ctx.lineWidth = 2;
    ctx.beginPath();
    let padStarted = false;
    for (let deg = 0; deg <= 360; deg += 12) {
      const rad = (deg * Math.PI) / 180;
      const p = this.projectPoint(
        { x: Math.cos(rad) * 5.5, y: 0, z: Math.sin(rad) * 5.5 },
        camPos,
        lookAt,
        width,
        height,
      );
      if (p.visible) {
        if (!padStarted) {
          ctx.moveTo(p.sx, p.sy);
          padStarted = true;
        } else {
          ctx.lineTo(p.sx, p.sy);
        }
      }
    }
    ctx.closePath();
    ctx.fill();
    ctx.stroke();
    ctx.restore();
  }

  private drawPerimeterProps(
    ctx: CanvasRenderingContext2D,
    width: number,
    height: number,
    camPos: Vec3,
    lookAt: Vec3,
    world: CelestialBody,
    solar: SolarHourState,
    lightingFactor: number,
  ): void {
    const projectedProps = this.terrainProps
      .map((prop) => {
        const base = this.projectPoint({ x: prop.x, y: 0, z: prop.z }, camPos, lookAt, width, height);
        const top = this.projectPoint(
          { x: prop.x, y: prop.height, z: prop.z },
          camPos,
          lookAt,
          width,
          height,
        );
        return { prop, base, top };
      })
      .filter((item) => item.base.visible && item.top.visible)
      .sort((a, b) => b.base.depth - a.base.depth);

    const featureColor = this.shadeHex(world.terrainTheme.featureColorHex, lightingFactor);
    const accentColor = this.shadeHex(world.terrainTheme.accentFeatureColorHex, lightingFactor);

    for (const { prop, base, top } of projectedProps) {
      const screenRadius = Math.max(4, (prop.radius * 420) / Math.max(8, base.depth));

      // Prop shadow
      if (solar.directLightIntensity > 0.05) {
        const shadowAlpha = 0.18 + solar.shadowHardness * 0.55;
        ctx.fillStyle = `rgba(5, 5, 8, ${shadowAlpha.toFixed(2)})`;
        ctx.beginPath();
        ctx.ellipse(
          base.sx + screenRadius * 0.9,
          base.sy + 2,
          screenRadius * 1.3,
          screenRadius * 0.45,
          0,
          0,
          Math.PI * 2,
        );
        ctx.fill();
      }

      if (world.terrainTheme.kind === 'moon-craters') {
        ctx.fillStyle = featureColor;
        ctx.strokeStyle = accentColor;
        ctx.lineWidth = 1.5;
        ctx.beginPath();
        ctx.ellipse(base.sx, base.sy, screenRadius * 1.4, screenRadius * 0.55, 0, 0, Math.PI * 2);
        ctx.fill();
        ctx.stroke();
      } else if (world.terrainTheme.kind === 'earth-meadow-rocks' && prop.kind === 'tree') {
        ctx.fillStyle = accentColor;
        ctx.beginPath();
        ctx.moveTo(top.sx, top.sy);
        ctx.lineTo(base.sx - screenRadius, base.sy);
        ctx.lineTo(base.sx + screenRadius, base.sy);
        ctx.closePath();
        ctx.fill();
      } else {
        ctx.fillStyle = prop.kind === 'ice-spire' ? accentColor : featureColor;
        ctx.beginPath();
        ctx.moveTo(top.sx, top.sy);
        ctx.lineTo(base.sx - screenRadius, base.sy);
        ctx.lineTo(base.sx + screenRadius * 0.85, base.sy + 2);
        ctx.closePath();
        ctx.fill();
      }
    }
  }

  private drawLanderShadow(
    ctx: CanvasRenderingContext2D,
    width: number,
    height: number,
    camPos: Vec3,
    lookAt: Vec3,
    landerVisualY: number,
    solar: SolarHourState,
  ): void {
    if (solar.directLightIntensity <= 0.02) {
      return;
    }
    const elevRad = Math.max(0.08, (Math.max(2, solar.solarElevationDeg) * Math.PI) / 180);
    const shadowOffset = Math.min(12, 2.2 / Math.tan(elevRad));
    const padShadowCenter = this.projectPoint(
      { x: shadowOffset, y: 0, z: 0 },
      camPos,
      lookAt,
      width,
      height,
    );
    if (!padShadowCenter.visible) {
      return;
    }

    const altitudeAttenuation = Math.max(0.25, 1 - landerVisualY / 140);
    const alpha = (0.2 + solar.shadowHardness * 0.65) * altitudeAttenuation;
    const rx = (28 + (1 - solar.shadowHardness) * 14) * altitudeAttenuation;
    const ry = rx * 0.42;

    ctx.save();
    ctx.fillStyle = `rgba(0, 0, 0, ${alpha.toFixed(2)})`;
    ctx.beginPath();
    ctx.ellipse(padShadowCenter.sx, padShadowCenter.sy, rx, ry, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.restore();
  }

  private drawLander3d(
    ctx: CanvasRenderingContext2D,
    width: number,
    height: number,
    camPos: Vec3,
    lookAt: Vec3,
    landerVisualY: number,
    lander: LanderState,
    lightingFactor: number,
  ): void {
    const center = this.projectPoint(
      { x: 0, y: landerVisualY + 1.8, z: 0 },
      camPos,
      lookAt,
      width,
      height,
    );
    if (!center.visible) {
      return;
    }

    const scale = Math.max(0.55, 34 / Math.max(12, center.depth));
    ctx.save();
    ctx.translate(center.sx, center.sy);
    ctx.scale(scale, scale);

    if (lander.status === 'crashed') {
      // Destroyed lander debris state (FR-011)
      ctx.fillStyle = '#8F3926';
      ctx.beginPath();
      ctx.moveTo(-24, 12);
      ctx.lineTo(-8, -6);
      ctx.lineTo(14, 4);
      ctx.lineTo(26, 14);
      ctx.closePath();
      ctx.fill();

      ctx.strokeStyle = '#C96A32';
      ctx.lineWidth = 2.5;
      ctx.beginPath();
      ctx.moveTo(-28, 14);
      ctx.lineTo(-14, -4);
      ctx.moveTo(10, 0);
      ctx.lineTo(28, 12);
      ctx.stroke();
      ctx.restore();
      return;
    }

    // Thruster flame plume when active & has fuel
    if (lander.isThrusterActive && lander.fuelPercentage > 0) {
      const plumeGrad = ctx.createLinearGradient(0, 14, 0, 52);
      plumeGrad.addColorStop(0, '#FFF4C2');
      plumeGrad.addColorStop(0.5, '#FF942E');
      plumeGrad.addColorStop(1, 'rgba(217, 56, 20, 0)');
      ctx.fillStyle = plumeGrad;
      ctx.beginPath();
      ctx.moveTo(-9, 14);
      ctx.lineTo(9, 14);
      ctx.lineTo(0, 52);
      ctx.closePath();
      ctx.fill();
    }

    // Landing legs
    ctx.strokeStyle = this.shadeHex('#B8BEC4', lightingFactor);
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(-12, 8);
    ctx.lineTo(-24, 22);
    ctx.moveTo(12, 8);
    ctx.lineTo(24, 22);
    ctx.moveTo(0, 10);
    ctx.lineTo(0, 23);
    ctx.stroke();

    // Spacecraft main module (gold thermal foil + metallic hull — zero Weincode colors)
    ctx.fillStyle = this.shadeHex('#D4A438', lightingFactor);
    ctx.fillRect(-14, -6, 28, 16);

    ctx.fillStyle = this.shadeHex('#D8DEE3', lightingFactor);
    ctx.beginPath();
    ctx.moveTo(-16, -6);
    ctx.lineTo(0, -24);
    ctx.lineTo(16, -6);
    ctx.closePath();
    ctx.fill();

    ctx.restore();
  }

  private projectPoint(
    point: Vec3,
    camPos: Vec3,
    lookAt: Vec3,
    width: number,
    height: number,
  ): ProjectedPoint {
    const fx = lookAt.x - camPos.x;
    const fy = lookAt.y - camPos.y;
    const fz = lookAt.z - camPos.z;
    const fLen = Math.hypot(fx, fy, fz) || 1;
    const forward = { x: fx / fLen, y: fy / fLen, z: fz / fLen };

    const upRef = { x: 0, y: 1, z: 0 };
    const rx = forward.y * upRef.z - forward.z * upRef.y;
    const ry = forward.z * upRef.x - forward.x * upRef.z;
    const rz = forward.x * upRef.y - forward.y * upRef.x;
    const rLen = Math.hypot(rx, ry, rz) || 1;
    const right = { x: rx / rLen, y: ry / rLen, z: rz / rLen };

    const up = {
      x: right.y * forward.z - right.z * forward.y,
      y: right.z * forward.x - right.x * forward.z,
      z: right.x * forward.y - right.y * forward.x,
    };

    const dx = point.x - camPos.x;
    const dy = point.y - camPos.y;
    const dz = point.z - camPos.z;

    const cx = dx * right.x + dy * right.y + dz * right.z;
    const cy = dx * up.x + dy * up.y + dz * up.z;
    const cz = dx * forward.x + dy * forward.y + dz * forward.z;

    if (cz <= 1.0) {
      return { sx: 0, sy: 0, depth: cz, visible: false };
    }

    const focalLength = Math.min(width, height) * 0.85;
    const sx = width * 0.5 + (cx / cz) * focalLength;
    const sy = height * 0.5 - (cy / cz) * focalLength;

    return { sx, sy, depth: cz, visible: true };
  }

  private computeSurfaceLightingFactor(solar: SolarHourState): number {
    const combined = solar.directLightIntensity * 0.72 + solar.ambientLightIntensity * 0.48;
    return Math.max(0.14, Math.min(1.0, combined));
  }

  private shadeHex(hex: string, factor: number): string {
    const clean = hex.replace('#', '');
    const r = Math.round((parseInt(clean.substring(0, 2), 16) || 0) * factor);
    const g = Math.round((parseInt(clean.substring(2, 4), 16) || 0) * factor);
    const b = Math.round((parseInt(clean.substring(4, 6), 16) || 0) * factor);
    const toHex = (n: number) => Math.max(0, Math.min(255, n)).toString(16).padStart(2, '0');
    return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
  }

  private generateDeterministicProps(): TerrainProp[] {
    const props: TerrainProp[] = [];
    const kinds: TerrainProp['kind'][] = ['rock', 'tree', 'crater', 'ice-spire'];
    for (let i = 0; i < 24; i++) {
      const angle = (i / 24) * Math.PI * 2 + (i % 3) * 0.15;
      const dist = 10 + (i % 4) * 6.5;
      props.push({
        x: Math.cos(angle) * dist,
        z: Math.sin(angle) * dist,
        radius: 1.2 + (i % 3) * 0.75,
        height: 1.6 + (i % 4) * 1.1,
        kind: kinds[i % kinds.length],
      });
    }
    return props;
  }
}
