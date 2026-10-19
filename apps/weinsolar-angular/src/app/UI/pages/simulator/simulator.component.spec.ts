import { ComponentFixture, TestBed } from '@angular/core/testing';
import { CelestialBodyGateway } from '../../../domain/models/celestial-body/gateway/celestial-body-gateway';
import { CelestialBodyLocalAdapter } from '../../../infraestructure/driven-adapter/celestial-body-local/celestial-body-local.adapter';
import { SimulatorComponent } from './simulator.component';

describe('SimulatorComponent (T051 — US1..US4 Integration)', () => {
  let fixture: ComponentFixture<SimulatorComponent>;
  let component: SimulatorComponent;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SimulatorComponent],
      providers: [{ provide: CelestialBodyGateway, useClass: CelestialBodyLocalAdapter }],
    }).compileComponents();

    fixture = TestBed.createComponent(SimulatorComponent);
    component = fixture.componentInstance;
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

  it('should start descent mission when selecting a world and reset in-flight state on resetInFlight() (FR-003, FR-018)', () => {
    const mars = component.worlds().find((w) => w.id === 'mars')!;
    component.selectWorld(mars);
    fixture.detectChanges();

    expect(component.selectedWorld()?.id).toBe('mars');
    expect(component.landerState()?.altitude).toBe(500);

    // Advance one simulation step with thruster active
    component.setThruster(true);
    component.advanceSimulationStep(0.04);
    expect(component.landerState()!.altitude).toBeLessThan(500);
    expect(component.landerState()!.fuelPercentage).toBeLessThan(100);

    // In-flight reset restores initial conditions immediately
    component.resetInFlight();
    expect(component.landerState()!.altitude).toBe(500);
    expect(component.landerState()!.verticalVelocity).toBe(-20.0);
    expect(component.landerState()!.fuelPercentage).toBe(100);
    expect(component.missionAttempt()!.outcome).toBe('inProgress');
  });

  it('should unlock Solar Hour on safe landing and immediately relock it on retryMission() (FR-014, FR-017, RN-06)', () => {
    const moon = component.worlds().find((w) => w.id === 'moon')!;
    component.selectWorld(moon);

    // Force a near-surface safe touchdown step
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

    // Update solar elevation to sunset
    component.updateSolarElevation(8);
    expect(component.solarHourState()?.solarElevationDeg).toBe(8);

    // Retry mission -> relocks Solar Hour and restores initial descent
    component.retryMission();
    fixture.detectChanges();

    expect(component.isSolarHourUnlocked()).toBe(false);
    expect(component.missionAttempt()?.outcome).toBe('inProgress');
    expect(component.landerState()?.altitude).toBe(500);
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
