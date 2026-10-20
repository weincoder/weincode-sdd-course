import { TestBed } from '@angular/core/testing';
import { SolarHourState } from '../models/simulation/solar-hour-state';
import { ResolveCameraModeUseCase } from './resolve-camera-mode.use-case';

describe('ResolveCameraModeUseCase (T013 — RN-11)', () => {
  let useCase: ResolveCameraModeUseCase;

  const baseSolarHour: SolarHourState = {
    isUnlocked: false,
    solarElevationDeg: 65,
    cameraAzimuthDeg: 0,
    zenithColorHex: '#1E5799',
    horizonColorHex: '#7DB9E8',
    sunHaloColorHex: '#FFF5D6',
    sunDiscColorHex: '#FFF4E0',
    shadowHardness: 0.65,
    ambientLightIntensity: 0.78,
    directLightIntensity: 1.0,
  };

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [ResolveCameraModeUseCase],
    });
    useCase = TestBed.inject(ResolveCameraModeUseCase);
  });

  it('should return lateralFollow when SolarHourState is locked (RN-11)', () => {
    expect(useCase.execute({ ...baseSolarHour, isUnlocked: false })).toBe('lateralFollow');
  });

  it('should return orbit when SolarHourState is unlocked (RN-11)', () => {
    expect(useCase.execute({ ...baseSolarHour, isUnlocked: true })).toBe('orbit');
  });
});
