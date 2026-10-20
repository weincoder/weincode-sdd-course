import { ChangeDetectionStrategy, Component, computed, input, output } from '@angular/core';
import { CelestialBody } from '../../../../domain/models/celestial-body/celestial-body';
import { VisualQuality } from '../../../../domain/models/scene/visual-quality';
import { LanderState } from '../../../../domain/models/simulation/lander-state';
import { TelemetryBadgeComponent } from '../../atoms/telemetry-badge/telemetry-badge.component';
import { QualityToggleComponent } from '../../molecules/quality-toggle/quality-toggle.component';

@Component({
  selector: 'app-weincode-cockpit-hud',
  imports: [TelemetryBadgeComponent, QualityToggleComponent],
  changeDetection: ChangeDetectionStrategy.OnPush,
  styles: [
    `
      .hud {
        display: flex;
        flex-direction: column;
        gap: 0.65rem;
        padding: 0.9rem 1.2rem;
        background-color: #18084D;
        border: 2px solid #5236FF;
        border-radius: 0.85rem;
        color: #FFFFFF;
      }
      .hud__top-row {
        display: flex;
        align-items: center;
        justify-content: space-between;
        flex-wrap: wrap;
        gap: 0.75rem;
      }
      .hud__brand {
        display: flex;
        align-items: center;
        gap: 0.6rem;
      }
      .hud__world-title {
        font-size: 1.1rem;
        font-weight: 800;
        color: #FFFFFF;
      }
      .hud__scale-pill {
        padding: 0.2rem 0.6rem;
        background-color: #5236FF;
        color: #FFFFFF;
        border-radius: 999px;
        font-size: 0.76rem;
        font-weight: 700;
      }
      .hud__actions {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        flex-wrap: wrap;
      }
      .hud__autoland-btn {
        padding: 0.4rem 0.85rem;
        background-color: #18084D;
        color: #FFFFFF;
        border: 1px solid #5236FF;
        border-radius: 0.45rem;
        font-size: 0.78rem;
        font-weight: 700;
        cursor: pointer;
      }
      .hud__autoland-btn--active {
        background-color: #5236FF;
        border-color: #FFFFFF;
      }
      .hud__reset-btn {
        padding: 0.4rem 0.85rem;
        background-color: #18084D;
        color: #FFFFFF;
        border: 1px solid #A599FF;
        border-radius: 0.45rem;
        font-size: 0.78rem;
        font-weight: 700;
        cursor: pointer;
      }
      .hud__reset-btn:hover {
        border-color: #5236FF;
      }
      .hud__grid {
        display: flex;
        flex-wrap: wrap;
        gap: 0.6rem;
      }
      .hud__alerts {
        display: flex;
        flex-wrap: wrap;
        gap: 0.6rem;
      }
      .hud__alert-pill {
        padding: 0.3rem 0.75rem;
        background-color: #5236FF;
        color: #FFFFFF;
        border: 1px solid #FFFFFF;
        border-radius: 0.4rem;
        font-size: 0.76rem;
        font-weight: 700;
      }
    `,
  ],
  template: `
    <header class="hud" data-testid="weincode-cockpit-hud">
      <div class="hud__top-row">
        <div class="hud__brand">
          <span class="hud__world-title">Cabina Weincode · {{ world().nameEs }}</span>
          <span class="hud__scale-pill">Escala ×{{ world().timeScale }}</span>
        </div>

        <div class="hud__actions">
          <app-quality-toggle
            [value]="visualQuality()"
            (valueChange)="visualQualityChanged.emit($event)"
          />

          @if (landerState().status === 'descending') {
            <button
              type="button"
              class="hud__autoland-btn"
              [class.hud__autoland-btn--active]="isAutopilotActive()"
              data-testid="auto-land-btn"
              (click)="autoLandRequested.emit()"
            >
              {{ isAutopilotActive() ? 'Piloto automático: ACTIVO' : 'Aterrizaje automático' }}
            </button>
          }

          <button
            type="button"
            class="hud__reset-btn"
            data-testid="in-flight-reset-btn"
            (click)="resetRequested.emit()"
          >
            Reiniciar
          </button>
        </div>
      </div>

      <div class="hud__grid">
        <app-telemetry-badge
          label="Altitud"
          [value]="altitudeFormatted()"
          [subtext]="'Techo: ' + world().ceilingAltitude + ' m'"
          [highlighted]="landerState().isNearCeiling"
        />
        <app-telemetry-badge
          label="Velocidad vertical"
          [value]="velocityFormatted()"
          [subtext]="velocityStatusText()"
          [highlighted]="!landerState().isVelocitySafe"
        />
        <app-telemetry-badge
          label="Combustible"
          [value]="fuelFormatted()"
          [subtext]="fuelStatusText()"
          [highlighted]="landerState().fuelPercentage <= 0"
        />
        <app-telemetry-badge
          label="Gravedad"
          [value]="world().gravity + ' m/s²'"
          [subtext]="'Umbral seguro: ≤ 2,0 m/s'"
        />
      </div>

      @if (landerState().isNearCeiling || landerState().fuelPercentage <= 0) {
        <div class="hud__alerts">
          @if (landerState().isNearCeiling) {
            <span class="hud__alert-pill">
              ALERTA DE TECHO: Próximo a pérdida de señal ({{ world().ceilingAltitude }} m)
            </span>
          }
          @if (landerState().fuelPercentage <= 0) {
            <span class="hud__alert-pill">Sin combustible — Caída libre</span>
          }
        </div>
      }
    </header>
  `,
})
export class WeincodeCockpitHudComponent {
  readonly world = input.required<CelestialBody>();
  readonly landerState = input.required<LanderState>();
  readonly isAutopilotActive = input<boolean>(false);
  readonly visualQuality = input<VisualQuality>('high');

  readonly autoLandRequested = output<void>();
  readonly resetRequested = output<void>();
  readonly visualQualityChanged = output<VisualQuality>();

  readonly altitudeFormatted = computed(() => `${this.landerState().altitude.toFixed(1)} m`);
  readonly velocityFormatted = computed(
    () => `${this.landerState().verticalVelocity.toFixed(1)} m/s`,
  );
  readonly fuelFormatted = computed(() => `${Math.round(this.landerState().fuelPercentage)}%`);

  readonly velocityStatusText = computed(() =>
    this.landerState().isVelocitySafe ? 'VELOCIDAD SEGURA (≤ 2,0 m/s)' : 'PELIGRO (> 2,0 m/s)',
  );

  readonly fuelStatusText = computed(() =>
    this.landerState().fuelPercentage <= 0 ? 'Sin combustible' : 'Reserva operativa',
  );
}
