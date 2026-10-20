import { ComponentFixture, TestBed } from '@angular/core/testing';
import { CelestialBody } from '../../../domain/models/celestial-body/celestial-body';
import { CelestialBodyGateway } from '../../../domain/models/celestial-body/gateway/celestial-body-gateway';
import { LanderState } from '../../../domain/models/simulation/lander-state';
import {
  MAX_THRUST_ACCELERATION_MPS2,
  SimulateDescentStepUseCase,
} from '../../../domain/usecase/simulate-descent-step.use-case';
import referenceFixture from '../../../domain/usecase/__fixtures__/reference-trajectories.json';
import { CelestialBodyLocalAdapter } from '../../../infraestructure/driven-adapter/celestial-body-local/celestial-body-local.adapter';
import { SimulatorComponent } from './simulator.component';

interface ReferenceTrajectoryEntry {
  readonly worldId: string;
  readonly profile: string;
  readonly finalAttempt: {
    readonly worldId: string;
    readonly outcome: string;
    readonly touchdownVelocity: number | null;
    readonly remainingFuel: number;
    readonly isSolarHourUnlocked: boolean;
    readonly failureReasonEs: string | null;
  };
}

function impactTargetThruster(world: CelestialBody, state: LanderState): boolean {
  if (state.status !== 'descending' || state.fuelPercentage <= 0) {
    return false;
  }
  const netBrakeAccel = Math.max(2.0, MAX_THRUST_ACCELERATION_MPS2 - world.gravity);
  const targetImpactSpeed = 2.4;
  const stoppingDistance =
    state.verticalVelocity < -targetImpactSpeed
      ? Math.max(
          0,
          state.verticalVelocity * state.verticalVelocity - targetImpactSpeed * targetImpactSpeed,
        ) /
        (2 * netBrakeAccel)
      : 0.0;
  if (state.altitude <= stoppingDistance + 18.0) {
    return state.verticalVelocity < -targetImpactSpeed;
  }
  return state.verticalVelocity < -28.0;
}

describe('SimulatorComponent (T039, T060, T070, T079 — v2 3D Scene & HUD Integration)', () => {
  let fixture: ComponentFixture<SimulatorComponent>;
  let component: SimulatorComponent;
  let simulateDescentStep: SimulateDescentStepUseCase;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SimulatorComponent],
      providers: [{ provide: CelestialBodyGateway, useClass: CelestialBodyLocalAdapter }],
    }).compileComponents();

    fixture = TestBed.createComponent(SimulatorComponent);
    component = fixture.componentInstance;
    simulateDescentStep = TestBed.inject(SimulateDescentStepUseCase);
    fixture.detectChanges();
  });

  it('should display the 4 selectable worlds with Spanish names and surface gravity on launch (FR-001, FR-002)', () => {
    const text = (fixture.nativeElement as HTMLElement).textContent ?? '';
    expect(text).toContain('Tierra');
    expect(text).toContain('Marte');
    expect(text).toContain('Luna');
    expect(text).toContain('Titán');
    expect(text).toContain('9.81');
    expect(text).toContain('3.71');
    expect(text).toContain('1.62');
    expect(text).toContain('1.352');
  });

  it('should mount <app-planetary-scene-3d> and <app-weincode-cockpit-hud> on world selection, decrease altitude over 10 steps, and switch to Lander_Destroyed on crash (T039 — US1)', () => {
    const mars = component.worlds().find((w) => w.id === 'mars')!;
    component.selectWorld(mars);
    fixture.detectChanges();

    const el = fixture.nativeElement as HTMLElement;
    expect(el.querySelector('app-planetary-scene-3d')).toBeTruthy();
    expect(el.querySelector('app-weincode-cockpit-hud')).toBeTruthy();

    const initialAlt = component.sceneDescriptor()!.lander.altitudeMeters;
    expect(initialAlt).toBe(500);
    expect(component.sceneDescriptor()!.lander.visibleNodeName).toBe('Lander_Intact');

    for (let i = 0; i < 10; i++) {
      component.advanceSimulationStep(1 / 60);
    }
    expect(component.sceneDescriptor()!.lander.altitudeMeters).toBeLessThan(initialAlt);

    // Force crash touchdown
    component.landerState.set({
      altitude: 0.01,
      verticalVelocity: -18.5,
      horizontalVelocity: 0,
      fuelPercentage: 40,
      isThrusterActive: false,
      status: 'descending',
      safeLandingThreshold: 2.0,
      isVelocitySafe: false,
      isNearCeiling: false,
    });
    component.advanceSimulationStep(0.01);
    fixture.detectChanges();

    expect(component.missionAttempt()?.outcome).toBe('failedImpact');
    expect(component.sceneDescriptor()?.lander.visibleNodeName).toBe('Lander_Destroyed');
  });

  it('should start descent mission when selecting a world and reset in-flight state on resetInFlight() (FR-003, FR-018)', () => {
    const mars = component.worlds().find((w) => w.id === 'mars')!;
    component.selectWorld(mars);
    fixture.detectChanges();

    expect(component.selectedWorld()?.id).toBe('mars');
    expect(component.landerState()?.altitude).toBe(500);

    component.setThruster(true);
    component.advanceSimulationStep(0.04);
    expect(component.landerState()!.altitude).toBeLessThan(500);
    expect(component.landerState()!.fuelPercentage).toBeLessThan(100);

    component.resetInFlight();
    expect(component.landerState()!.altitude).toBe(500);
    expect(component.landerState()!.verticalVelocity).toBe(-20.0);
    expect(component.landerState()!.fuelPercentage).toBe(100);
    expect(component.missionAttempt()!.outcome).toBe('inProgress');
  });

  it('should unlock Solar Hour on safe landing and immediately relock it on retryMission() (FR-014, FR-017, RN-06)', () => {
    const moon = component.worlds().find((w) => w.id === 'moon')!;
    component.selectWorld(moon);

    component.landerState.set({
      altitude: 0.001,
      verticalVelocity: -1.5,
      horizontalVelocity: 0,
      fuelPercentage: 62,
      isThrusterActive: false,
      status: 'descending',
      safeLandingThreshold: 2.0,
      isVelocitySafe: true,
      isNearCeiling: false,
    });
    component.advanceSimulationStep(0.001);
    fixture.detectChanges();

    expect(component.missionAttempt()?.outcome).toBe('success');
    expect(component.isSolarHourUnlocked()).toBe(true);

    component.updateSolarElevation(8);
    expect(component.solarHourState()?.solarElevationDeg).toBe(8);

    component.retryMission();
    fixture.detectChanges();

    expect(component.isSolarHourUnlocked()).toBe(false);
    expect(component.missionAttempt()?.outcome).toBe('inProgress');
    expect(component.landerState()?.altitude).toBe(500);
  });

  it('should produce identical MissionAttempt and sceneLighting when toggling quality every 60 ticks during reference profiles (c) and (d) (T060 — RN-09, RN-15, SC-010)', () => {
    const dt = 1 / 60;
    const expectedMap = referenceFixture as unknown as Record<string, ReferenceTrajectoryEntry>;
    const targetProfiles = ['c_safe_touchdown_le_2_0', 'd_impact_touchdown_gt_2_0'] as const;

    for (const world of component.worlds()) {
      for (const profileName of targetProfiles) {
        const key = `${world.id}__${profileName}`;
        const expected = expectedMap[key];
        expect(expected).withContext(`fixture entry ${key}`).toBeTruthy();

        component.selectWorld(world);

        let tick = 0;
        while (component.missionAttempt()?.outcome === 'inProgress' && tick < 4000) {
          if (tick % 60 === 0) {
            const nextQuality = (tick / 60) % 2 === 0 ? 'basic' : 'high';
            component.setVisualQuality(nextQuality);
            const lightingA = component.sceneLighting();
            component.setVisualQuality(nextQuality === 'high' ? 'basic' : 'high');
            const lightingB = component.sceneLighting();
            expect(lightingB).toEqual(lightingA);
          }

          const currentState = component.landerState()!;
          const shouldThrust =
            profileName === 'c_safe_touchdown_le_2_0'
              ? simulateDescentStep.computeAutopilotThruster(world, currentState)
              : impactTargetThruster(world, currentState);
          component.setThruster(shouldThrust);
          component.advanceSimulationStep(dt);
          tick++;
        }

        const finalAttempt = component.missionAttempt()!;
        expect(finalAttempt.outcome)
          .withContext(`${key} outcome`)
          .toBe(expected.finalAttempt.outcome as typeof finalAttempt.outcome);
        expect(finalAttempt.isSolarHourUnlocked)
          .withContext(`${key} isSolarHourUnlocked`)
          .toBe(expected.finalAttempt.isSolarHourUnlocked);
        expect(
          Math.abs(
            (finalAttempt.touchdownVelocity ?? 0) - (expected.finalAttempt.touchdownVelocity ?? 0),
          ),
        )
          .withContext(`${key} touchdownVelocity`)
          .toBeLessThanOrEqual(1e-9);
      }
    }
  });

  it('should update descriptor.lighting.sunDirection.y to sin(10°) when moving Solar Hour slider to 10° after safe landing, and keep 65° without slider on crash (T070 — US2)', () => {
    const earth = component.worlds().find((w) => w.id === 'earth')!;
    component.selectWorld(earth);

    // Safe landing
    component.landerState.set({
      altitude: 0.001,
      verticalVelocity: -1.2,
      horizontalVelocity: 0,
      fuelPercentage: 55,
      isThrusterActive: false,
      status: 'descending',
      safeLandingThreshold: 2.0,
      isVelocitySafe: true,
      isNearCeiling: false,
    });
    component.advanceSimulationStep(0.001);
    fixture.detectChanges();

    const slider = (fixture.nativeElement as HTMLElement).querySelector(
      '[data-testid="solar-elevation-slider"]',
    ) as HTMLInputElement;
    expect(slider).toBeTruthy();

    slider.value = '10';
    slider.dispatchEvent(new Event('input'));
    fixture.detectChanges();

    expect(component.sceneDescriptor()!.lighting.sunDirection.y).toBeCloseTo(
      Math.sin((10 * Math.PI) / 180),
      9,
    );

    // Now test crashed mission
    component.retryMission();
    component.landerState.set({
      altitude: 0.01,
      verticalVelocity: -15.0,
      horizontalVelocity: 0,
      fuelPercentage: 50,
      isThrusterActive: false,
      status: 'descending',
      safeLandingThreshold: 2.0,
      isVelocitySafe: false,
      isNearCeiling: false,
    });
    component.advanceSimulationStep(0.01);
    fixture.detectChanges();

    expect(component.missionAttempt()?.outcome).toBe('failedImpact');
    const sliderAfterCrash = (fixture.nativeElement as HTMLElement).querySelector(
      '[data-testid="solar-elevation-slider"]',
    );
    expect(sliderAfterCrash).toBeNull();
    expect(component.sceneDescriptor()!.lighting.solarElevationDeg).toBe(65);
  });

  it('should ignore ArrowLeft/ArrowRight during descent and after failure, and rotate cameraAzimuthDeg by ±5° normalized to [0°, 360°) after safe landing (T079 — US3, RN-11)', () => {
    const mars = component.worlds().find((w) => w.id === 'mars')!;
    component.selectWorld(mars);
    fixture.detectChanges();

    // During descent: ArrowLeft/ArrowRight ignored
    component.onKeyDown(new KeyboardEvent('keydown', { code: 'ArrowRight' }));
    component.onKeyDown(new KeyboardEvent('keydown', { code: 'ArrowLeft' }));
    expect(component.sceneDescriptor()!.cameraAzimuthDeg).toBe(0);

    // After safe landing: ArrowLeft/ArrowRight rotate ±5°
    component.landerState.set({
      altitude: 0.001,
      verticalVelocity: -1.1,
      horizontalVelocity: 0,
      fuelPercentage: 60,
      isThrusterActive: false,
      status: 'descending',
      safeLandingThreshold: 2.0,
      isVelocitySafe: true,
      isNearCeiling: false,
    });
    component.advanceSimulationStep(0.001);
    fixture.detectChanges();

    expect(component.cameraMode()).toBe('orbit');
    component.onKeyDown(new KeyboardEvent('keydown', { code: 'ArrowRight' }));
    expect(component.sceneDescriptor()!.cameraAzimuthDeg).toBe(5);

    component.onKeyDown(new KeyboardEvent('keydown', { code: 'ArrowLeft' }));
    component.onKeyDown(new KeyboardEvent('keydown', { code: 'ArrowLeft' }));
    expect(component.sceneDescriptor()!.cameraAzimuthDeg).toBe(355);

    // After crash: ArrowLeft/ArrowRight ignored
    component.retryMission();
    component.landerState.set({
      altitude: 0.01,
      verticalVelocity: -14.0,
      horizontalVelocity: 0,
      fuelPercentage: 40,
      isThrusterActive: false,
      status: 'descending',
      safeLandingThreshold: 2.0,
      isVelocitySafe: false,
      isNearCeiling: false,
    });
    component.advanceSimulationStep(0.01);
    fixture.detectChanges();

    expect(component.cameraMode()).toBe('lateralFollow');
    component.onKeyDown(new KeyboardEvent('keydown', { code: 'ArrowRight' }));
    expect(component.sceneDescriptor()!.cameraAzimuthDeg).toBe(0);
  });

  it('should return to world selection when changeWorld() is called (FR-017)', () => {
    const earth = component.worlds().find((w) => w.id === 'earth')!;
    component.selectWorld(earth);
    expect(component.selectedWorld()).toBeTruthy();

    component.changeWorld();
    fixture.detectChanges();

    expect(component.selectedWorld()).toBeNull();
    expect(component.isSolarHourUnlocked()).toBe(false);
  });

  it('should guide the lander to a safe landing automatically when toggleAutoLand() is activated', () => {
    const mars = component.worlds().find((w) => w.id === 'mars')!;
    component.selectWorld(mars);
    component.toggleAutoLand();
    fixture.detectChanges();

    expect(component.isAutopilotActive()).toBe(true);

    let steps = 0;
    while (component.missionAttempt()?.outcome === 'inProgress' && steps < 4000) {
      component.advanceSimulationStep(1 / 60);
      steps++;
    }

    expect(component.missionAttempt()?.outcome).toBe('success');
    expect(component.isSolarHourUnlocked()).toBe(true);
    expect(component.isAutopilotActive()).toBe(false);
  });
});
