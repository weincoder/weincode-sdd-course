import { Injectable } from '@angular/core';
import { CameraMode } from '../models/scene/camera-mode';
import { SolarHourState } from '../models/simulation/solar-hour-state';

@Injectable({ providedIn: 'root' })
export class ResolveCameraModeUseCase {
  execute(solarHour: SolarHourState): CameraMode {
    return solarHour.isUnlocked ? 'orbit' : 'lateralFollow';
  }
}
