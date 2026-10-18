import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';

@Component({
  selector: 'app-solar-hour-slider',
  changeDetection: ChangeDetectionStrategy.OnPush,
  styles: [
    `
      .solar-panel {
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
        padding: 1rem 1.25rem;
        background-color: #18084D;
        border: 2px solid #5236FF;
        border-radius: 0.85rem;
        color: #FFFFFF;
        min-width: 20rem;
      }
      .solar-panel__title {
        font-size: 0.9rem;
        font-weight: 800;
        letter-spacing: 0.05em;
        text-transform: uppercase;
        color: #FFFFFF;
      }
      .solar-panel__control {
        display: flex;
        flex-direction: column;
        gap: 0.3rem;
      }
      .solar-panel__label {
        display: flex;
        justify-content: space-between;
        font-size: 0.8rem;
        color: #A599FF;
        font-weight: 600;
      }
      .solar-panel__value {
        color: #FFFFFF;
        font-weight: 700;
      }
      .solar-panel__range {
        width: 100%;
        accent-color: #5236FF;
        cursor: pointer;
      }
    `,
  ],
  template: `
    <section class="solar-panel" data-testid="solar-hour-panel">
      <div class="solar-panel__title">Observación Crepuscular — Hora Solar</div>

      <div class="solar-panel__control">
        <label class="solar-panel__label" for="solar-elevation-slider">
          <span>Hora Solar (Elevación del Sol)</span>
          <span class="solar-panel__value">{{ solarElevationDeg().toFixed(0) }}°</span>
        </label>
        <input
          id="solar-elevation-slider"
          data-testid="solar-elevation-slider"
          class="solar-panel__range"
          type="range"
          min="-10"
          max="90"
          step="1"
          [value]="solarElevationDeg()"
          (input)="onElevationInput($event)"
        />
      </div>

      <div class="solar-panel__control">
        <label class="solar-panel__label" for="camera-azimuth-slider">
          <span>Giro Horizontal de Cámara (360°)</span>
          <span class="solar-panel__value">{{ cameraAzimuthDeg().toFixed(0) }}°</span>
        </label>
        <input
          id="camera-azimuth-slider"
          data-testid="camera-azimuth-slider"
          class="solar-panel__range"
          type="range"
          min="0"
          max="359"
          step="1"
          [value]="cameraAzimuthDeg()"
          (input)="onAzimuthInput($event)"
        />
      </div>
    </section>
  `,
})
export class SolarHourSliderComponent {
  readonly solarElevationDeg = input.required<number>();
  readonly cameraAzimuthDeg = input.required<number>();

  readonly solarElevationChanged = output<number>();
  readonly cameraAzimuthChanged = output<number>();

  onElevationInput(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.solarElevationChanged.emit(Number(target.value));
  }

  onAzimuthInput(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.cameraAzimuthChanged.emit(Number(target.value));
  }
}
