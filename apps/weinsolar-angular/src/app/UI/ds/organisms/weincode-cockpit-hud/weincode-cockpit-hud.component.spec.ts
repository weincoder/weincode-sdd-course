import { ComponentFixture, TestBed } from '@angular/core/testing';
import { CelestialBody } from '../../../../domain/models/celestial-body/celestial-body';
import { LanderState } from '../../../../domain/models/simulation/lander-state';
import { WeincodeCockpitHudComponent } from './weincode-cockpit-hud.component';

const MOCK_EARTH: CelestialBody = {
  id: 'earth',
  nameEs: 'Tierra',
  gravity: 9.81,
  atmosphericDensity: 1.225,
  timeScale: 2,
  initialAltitude: 500,
  ceilingAltitude: 750,
  initialVelocity: -25.0,
  initialFuel: 100.0,
  terrainTheme: {
    kind: 'earth-meadow-rocks',
    primarySurfaceHex: '#3B5E34',
    secondarySurfaceHex: '#2E4A28',
    featureColorHex: '#5C6468',
    accentFeatureColorHex: '#4A7A3D',
    landingPadColorHex: '#7A8288',
    landingPadTrimHex: '#C7A336',
  },
  skyOpticalProfile: {
    scientificReference: 'NASA Earth Observatory',
    descriptionEs: 'Dispersión de Rayleigh',
    shadowHardness: 0.65,
    hasAtmosphere: true,
    keyframes: [],
  },
  lightingProfile: {
    sunAzimuthDeg: 250,
    sunColorDayHex: '#FFF4E0',
    sunColorSunsetHex: '#FF7A2E',
    ambientDayIntensity: 0.45,
    twilightFadeDeg: 6,
    shadowSoftness: 0.35,
    scientificReference: 'NASA Earth Observatory',
  },
};

const DANGEROUS_STATE: LanderState = {
  altitude: 340,
  verticalVelocity: -12.4,
  horizontalVelocity: 0,
  fuelPercentage: 78,
  isThrusterActive: false,
  status: 'descending',
  safeLandingThreshold: 2.0,
  isVelocitySafe: false,
  isNearCeiling: false,
};

describe('WeincodeCockpitHudComponent (T057 — FR-019, FR-020, FR-021, FR-026)', () => {
  let fixture: ComponentFixture<WeincodeCockpitHudComponent>;
  let component: WeincodeCockpitHudComponent;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [WeincodeCockpitHudComponent],
    }).compileComponents();

    fixture = TestBed.createComponent(WeincodeCockpitHudComponent);
    component = fixture.componentInstance;
    fixture.componentRef.setInput('world', MOCK_EARTH);
    fixture.componentRef.setInput('landerState', DANGEROUS_STATE);
    fixture.detectChanges();
  });

  it('should render all required telemetry metrics in Spanish (FR-019, FR-026)', () => {
    const text = (fixture.nativeElement as HTMLElement).textContent ?? '';
    expect(text).toContain('Tierra');
    expect(text).toContain('9.81 m/s²');
    expect(text).toContain('340.0 m');
    expect(text).toContain('-12.4 m/s');
    expect(text).toContain('78%');
    expect(text).toContain('2,0 m/s');
    expect(text).toContain('750 m');
    expect(text).toContain('×2');
  });

  it('should switch velocity badge between PELIGRO (> 2,0 m/s) and VELOCIDAD SEGURA (≤ 2,0 m/s) (FR-020)', () => {
    let text = (fixture.nativeElement as HTMLElement).textContent ?? '';
    expect(text).toContain('PELIGRO (> 2,0 m/s)');

    fixture.componentRef.setInput('landerState', {
      ...DANGEROUS_STATE,
      verticalVelocity: -1.8,
      isVelocitySafe: true,
    });
    fixture.detectChanges();

    text = (fixture.nativeElement as HTMLElement).textContent ?? '';
    expect(text).toContain('VELOCIDAD SEGURA (≤ 2,0 m/s)');
  });

  it('should display "Sin combustible" when fuel reaches 0% and ceiling alert when isNearCeiling is true (FR-007, FR-019)', () => {
    fixture.componentRef.setInput('landerState', {
      ...DANGEROUS_STATE,
      altitude: 680,
      fuelPercentage: 0,
      isNearCeiling: true,
    });
    fixture.detectChanges();

    const text = (fixture.nativeElement as HTMLElement).textContent ?? '';
    expect(text).toContain('Sin combustible');
    expect(text).toContain('ALERTA DE TECHO');
  });

  it('should emit resetRequested when clicking the in-flight Reiniciar button (FR-018)', () => {
    let emitted = false;
    component.resetRequested.subscribe(() => {
      emitted = true;
    });

    const resetBtn = (fixture.nativeElement as HTMLElement).querySelector(
      '[data-testid="in-flight-reset-btn"]',
    ) as HTMLButtonElement;
    expect(resetBtn).toBeTruthy();
    resetBtn.click();
    expect(emitted).toBe(true);
  });

  it('should emit autoLandRequested when clicking the Aterrizaje automático button', () => {
    let emitted = false;
    component.autoLandRequested.subscribe(() => {
      emitted = true;
    });

    const autoLandBtn = (fixture.nativeElement as HTMLElement).querySelector(
      '[data-testid="auto-land-btn"]',
    ) as HTMLButtonElement;
    expect(autoLandBtn).toBeTruthy();
    expect(autoLandBtn.textContent).toContain('Aterrizaje automático');
    autoLandBtn.click();
    expect(emitted).toBe(true);
  });

  it('should strictly enforce the 4 official Weincode colors (#18084D, #5236FF, #A599FF, #FFFFFF) in HUD styles (FR-021)', () => {
    const hudHeader = (fixture.nativeElement as HTMLElement).querySelector(
      '[data-testid="weincode-cockpit-hud"]',
    ) as HTMLElement;
    expect(hudHeader).toBeTruthy();
    const computedBg = getComputedStyle(hudHeader).backgroundColor;
    // #18084D === rgb(24, 8, 77)
    expect(computedBg).toBe('rgb(24, 8, 77)');
  });
});
