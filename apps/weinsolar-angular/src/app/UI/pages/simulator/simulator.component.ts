import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  HostListener,
  OnInit,
  computed,
  inject,
  signal,
} from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { CelestialBody } from '../../../domain/models/celestial-body/celestial-body';
import { LanderState } from '../../../domain/models/simulation/lander-state';
import { MissionAttempt } from '../../../domain/models/simulation/mission-attempt';
import {
  INITIAL_SOLAR_ELEVATION_DEG,
  SolarHourState,
} from '../../../domain/models/simulation/solar-hour-state';
import { EvaluateSolarHourUseCase } from '../../../domain/usecase/evaluate-solar-hour.use-case';
import { GetCelestialBodiesUseCase } from '../../../domain/usecase/get-celestial-bodies.use-case';
import { SimulateDescentStepUseCase } from '../../../domain/usecase/simulate-descent-step.use-case';
import { ThrusterButtonComponent } from '../../ds/atoms/thruster-button/thruster-button.component';
import { MissionResultBannerComponent } from '../../ds/molecules/mission-result-banner/mission-result-banner.component';
import { SolarHourSliderComponent } from '../../ds/molecules/solar-hour-slider/solar-hour-slider.component';
import { WorldCardComponent } from '../../ds/molecules/world-card/world-card.component';
import { PlanetaryScene3dComponent } from '../../ds/organisms/planetary-scene-3d/planetary-scene-3d.component';
import { WeincodeCockpitHudComponent } from '../../ds/organisms/weincode-cockpit-hud/weincode-cockpit-hud.component';
import { SimulatorShellComponent } from '../../ds/templates/simulator-shell/simulator-shell.component';

@Component({
  selector: 'app-simulator',
  imports: [
    WorldCardComponent,
    ThrusterButtonComponent,
    MissionResultBannerComponent,
    SolarHourSliderComponent,
    WeincodeCockpitHudComponent,
    PlanetaryScene3dComponent,
    SimulatorShellComponent,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  styles: [
    `
      .selector-screen {
        min-height: 100vh;
        padding: 2.5rem 1.5rem;
        background-color: #18084D;
        color: #FFFFFF;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 2rem;
      }
      .selector-screen__header {
        text-align: center;
        max-width: 44rem;
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
      }
      .selector-screen__title {
        font-size: 2rem;
        font-weight: 900;
        color: #FFFFFF;
      }
      .selector-screen__subtitle {
        font-size: 0.98rem;
        color: #A599FF;
        line-height: 1.5;
      }
      .selector-screen__grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(16.5rem, 1fr));
        gap: 1.25rem;
        width: 100%;
        max-width: 68rem;
      }
      .bottom-controls {
        display: flex;
        flex-wrap: wrap;
        align-items: flex-end;
        justify-content: space-between;
        width: 100%;
        gap: 1rem;
      }
    `,
  ],
  template: `
    @if (selectedWorld(); as world) {
      @if (landerState(); as currentLander) {
        @if (solarHourState(); as currentSolar) {
          <app-simulator-shell>
            <app-planetary-scene-3d
              slot="scene"
              [world]="world"
              [landerState]="currentLander"
              [solarHourState]="currentSolar"
              (cameraAzimuthChanged)="updateCameraAzimuth($event)"
            />

            <app-weincode-cockpit-hud
              slot="hud-top"
              [world]="world"
              [landerState]="currentLander"
              [isAutopilotActive]="isAutopilotActive()"
              (autoLandRequested)="toggleAutoLand()"
              (resetRequested)="resetInFlight()"
            />

            <div slot="hud-bottom" class="bottom-controls">
              @if (missionAttempt(); as attempt) {
                @if (attempt.outcome === 'inProgress') {
                  <app-thruster-button
                    [isActive]="currentLander.isThrusterActive"
                    [isOutOfFuel]="currentLander.fuelPercentage <= 0"
                    (thrusterChanged)="setThruster($event)"
                  />
                } @else {
                  <app-mission-result-banner
                    [world]="world"
                    [attempt]="attempt"
                    (retryRequested)="retryMission()"
                    (changeWorldRequested)="changeWorld()"
                  />
                }
              }

              @if (isSolarHourUnlocked()) {
                <app-solar-hour-slider
                  [solarElevationDeg]="currentSolar.solarElevationDeg"
                  [cameraAzimuthDeg]="currentSolar.cameraAzimuthDeg"
                  (solarElevationChanged)="updateSolarElevation($event)"
                  (cameraAzimuthChanged)="updateCameraAzimuth($event)"
                />
              }
            </div>
          </app-simulator-shell>
        }
      }
    } @else {
      <main class="selector-screen" data-testid="world-selector-screen">
        <header class="selector-screen__header">
          <h1 class="selector-screen__title">WeinSolar — Descenso Planetario y Hora Solar</h1>
          <p class="selector-screen__subtitle">
            Selecciona un cuerpo celeste para iniciar el descenso vertical con gravedad y atmósfera
            reales. Aterriza a <strong>≤ 2,0 m/s</strong> para desbloquear la observación
            crepuscular <strong>Hora Solar</strong>.
          </p>
        </header>

        <section class="selector-screen__grid">
          @for (world of worlds(); track world.id) {
            <app-world-card [world]="world" (worldSelected)="selectWorld($event)" />
          }
        </section>
      </main>
    }
  `,
})
export class SimulatorComponent implements OnInit {
  private readonly getCelestialBodies = inject(GetCelestialBodiesUseCase);
  private readonly simulateDescentStep = inject(SimulateDescentStepUseCase);
  private readonly evaluateSolarHour = inject(EvaluateSolarHourUseCase);
  private readonly destroyRef = inject(DestroyRef);

  readonly worlds = toSignal(this.getCelestialBodies.getAll(), { initialValue: [] });
  readonly selectedWorld = signal<CelestialBody | null>(null);
  readonly landerState = signal<LanderState | null>(null);
  readonly missionAttempt = signal<MissionAttempt | null>(null);
  readonly solarElevationDeg = signal<number>(INITIAL_SOLAR_ELEVATION_DEG);
  readonly cameraAzimuthDeg = signal<number>(0.0);
  readonly isWindowPaused = signal<boolean>(false);
  readonly isAutopilotActive = signal<boolean>(false);

  readonly isSolarHourUnlocked = computed(
    () => this.missionAttempt()?.outcome === 'success' && Boolean(this.missionAttempt()?.isSolarHourUnlocked),
  );

  readonly solarHourState = computed<SolarHourState | null>(() => {
    const world = this.selectedWorld();
    const attempt = this.missionAttempt();
    if (!world || !attempt) {
      return null;
    }
    return this.evaluateSolarHour.evaluate({
      world,
      attempt,
      solarElevationDeg: this.solarElevationDeg(),
      cameraAzimuthDeg: this.cameraAzimuthDeg(),
    });
  });

  private animationFrameId: number | null = null;
  private lastFrameTimestamp: number | null = null;

  ngOnInit(): void {
    const onVisibilityChange = () => {
      if (typeof document !== 'undefined' && document.hidden) {
        this.pauseLoopOnFocusLoss();
      } else {
        this.resumeLoopAfterFocus();
      }
    };
    const onWindowBlur = () => this.pauseLoopOnFocusLoss();
    const onWindowFocus = () => this.resumeLoopAfterFocus();

    if (typeof document !== 'undefined') {
      document.addEventListener('visibilitychange', onVisibilityChange);
    }
    if (typeof window !== 'undefined') {
      window.addEventListener('blur', onWindowBlur);
      window.addEventListener('focus', onWindowFocus);
    }

    this.destroyRef.onDestroy(() => {
      this.stopLoop();
      if (typeof document !== 'undefined') {
        document.removeEventListener('visibilitychange', onVisibilityChange);
      }
      if (typeof window !== 'undefined') {
        window.removeEventListener('blur', onWindowBlur);
        window.removeEventListener('focus', onWindowFocus);
      }
    });
  }

  selectWorld(world: CelestialBody): void {
    this.selectedWorld.set(world);
    this.initializeMissionForWorld(world);
  }

  resetInFlight(): void {
    const world = this.selectedWorld();
    if (!world) {
      return;
    }
    this.initializeMissionForWorld(world);
  }

  retryMission(): void {
    const world = this.selectedWorld();
    if (!world) {
      return;
    }
    this.initializeMissionForWorld(world);
  }

  changeWorld(): void {
    this.stopLoop();
    this.selectedWorld.set(null);
    this.landerState.set(null);
    this.missionAttempt.set(null);
    this.solarElevationDeg.set(INITIAL_SOLAR_ELEVATION_DEG);
    this.cameraAzimuthDeg.set(0.0);
    this.isAutopilotActive.set(false);
  }

  toggleAutoLand(): void {
    const world = this.selectedWorld();
    const current = this.landerState();
    const attempt = this.missionAttempt();
    if (!world || !current || !attempt || attempt.outcome !== 'inProgress') {
      return;
    }

    const nextActive = !this.isAutopilotActive();
    if (nextActive && !this.simulateDescentStep.isAutopilotRecoverable(world, current)) {
      this.initializeMissionForWorld(world);
    }
    this.isAutopilotActive.set(nextActive);
    const activeState = this.landerState();
    if (activeState) {
      const shouldThrust = nextActive
        ? this.simulateDescentStep.computeAutopilotThruster(world, activeState)
        : false;
      this.landerState.set({
        ...activeState,
        isThrusterActive: shouldThrust,
      });
    }
  }

  setThruster(active: boolean): void {
    const current = this.landerState();
    const attempt = this.missionAttempt();
    if (!current || !attempt || attempt.outcome !== 'inProgress') {
      return;
    }
    if (active && this.isAutopilotActive()) {
      this.isAutopilotActive.set(false);
    }
    const canThrust = active && current.fuelPercentage > 0;
    this.landerState.set({
      ...current,
      isThrusterActive: canThrust,
    });
  }

  updateSolarElevation(elevationDeg: number): void {
    if (!this.isSolarHourUnlocked()) {
      return;
    }
    this.solarElevationDeg.set(elevationDeg);
  }

  updateCameraAzimuth(azimuthDeg: number): void {
    if (!this.isSolarHourUnlocked()) {
      return;
    }
    this.cameraAzimuthDeg.set(azimuthDeg);
  }

  advanceSimulationStep(realDeltaSeconds: number): void {
    const world = this.selectedWorld();
    const state = this.landerState();
    const attempt = this.missionAttempt();
    if (!world || !state || !attempt || attempt.outcome !== 'inProgress') {
      return;
    }

    const stepState = this.isAutopilotActive()
      ? {
          ...state,
          isThrusterActive: this.simulateDescentStep.computeAutopilotThruster(world, state),
        }
      : state;

    const next = this.simulateDescentStep.step({
      world,
      state: stepState,
      attempt,
      realDeltaSeconds,
    });
    this.landerState.set(next.state);
    this.missionAttempt.set(next.attempt);
    if (next.attempt.outcome !== 'inProgress') {
      this.isAutopilotActive.set(false);
    }
  }

  @HostListener('window:keydown', ['$event'])
  onKeyDown(event: KeyboardEvent): void {
    if (event.code === 'Space' || event.code === 'ArrowUp') {
      if (this.missionAttempt()?.outcome === 'inProgress') {
        event.preventDefault();
        this.setThruster(true);
      }
    }
  }

  @HostListener('window:keyup', ['$event'])
  onKeyUp(event: KeyboardEvent): void {
    if (event.code === 'Space' || event.code === 'ArrowUp') {
      this.setThruster(false);
    }
  }

  private initializeMissionForWorld(world: CelestialBody): void {
    this.stopLoop();
    const initial = this.simulateDescentStep.createInitialState(world);
    this.landerState.set(initial.state);
    this.missionAttempt.set(initial.attempt);
    this.solarElevationDeg.set(INITIAL_SOLAR_ELEVATION_DEG);
    this.cameraAzimuthDeg.set(0.0);
    this.isAutopilotActive.set(false);
    this.startLoop();
  }

  private startLoop(): void {
    if (typeof requestAnimationFrame === 'undefined') {
      return;
    }
    this.lastFrameTimestamp = null;
    const tick = (timestamp: number) => {
      if (this.missionAttempt()?.outcome !== 'inProgress') {
        this.animationFrameId = null;
        return;
      }
      if (!this.isWindowPaused()) {
        if (this.lastFrameTimestamp !== null) {
          const dtSeconds = (timestamp - this.lastFrameTimestamp) / 1000;
          this.advanceSimulationStep(dtSeconds);
        }
        this.lastFrameTimestamp = timestamp;
      }
      this.animationFrameId = requestAnimationFrame(tick);
    };
    this.animationFrameId = requestAnimationFrame(tick);
  }

  private stopLoop(): void {
    if (this.animationFrameId !== null && typeof cancelAnimationFrame !== 'undefined') {
      cancelAnimationFrame(this.animationFrameId);
      this.animationFrameId = null;
    }
    this.lastFrameTimestamp = null;
  }

  private pauseLoopOnFocusLoss(): void {
    this.isWindowPaused.set(true);
    this.lastFrameTimestamp = null;
    this.setThruster(false);
  }

  private resumeLoopAfterFocus(): void {
    this.isWindowPaused.set(false);
    this.lastFrameTimestamp = null;
  }
}
