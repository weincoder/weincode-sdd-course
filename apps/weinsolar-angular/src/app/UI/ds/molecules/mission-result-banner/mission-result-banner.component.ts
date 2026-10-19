import { ChangeDetectionStrategy, Component, computed, input, output } from '@angular/core';
import { CelestialBody } from '../../../../domain/models/celestial-body/celestial-body';
import { MissionAttempt } from '../../../../domain/models/simulation/mission-attempt';

@Component({
  selector: 'app-mission-result-banner',
  changeDetection: ChangeDetectionStrategy.OnPush,
  styles: [
    `
      .result-banner {
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
        padding: 1.15rem 1.4rem;
        background-color: #18084D;
        border: 2px solid #5236FF;
        border-radius: 0.85rem;
        color: #FFFFFF;
        max-width: 28rem;
      }
      .result-banner__title {
        font-size: 1.15rem;
        font-weight: 800;
        color: #FFFFFF;
      }
      .result-banner__detail {
        font-size: 0.86rem;
        color: #A599FF;
        line-height: 1.4;
      }
      .result-banner__reference {
        font-size: 0.75rem;
        color: #A599FF;
        border-top: 1px solid #A599FF;
        padding-top: 0.5rem;
      }
      .result-banner__actions {
        display: flex;
        gap: 0.75rem;
        flex-wrap: wrap;
      }
      .result-banner__btn {
        padding: 0.55rem 1.1rem;
        border-radius: 0.5rem;
        font-size: 0.85rem;
        font-weight: 700;
        cursor: pointer;
        border: 1px solid #5236FF;
        background-color: #5236FF;
        color: #FFFFFF;
      }
      .result-banner__btn--secondary {
        background-color: #18084D;
        border-color: #A599FF;
        color: #FFFFFF;
      }
    `,
  ],
  template: `
    <aside class="result-banner" data-testid="mission-result-banner">
      <h2 class="result-banner__title">{{ titleText() }}</h2>
      <p class="result-banner__detail">{{ summaryText() }}</p>

      @if (attempt().outcome === 'success') {
        <p class="result-banner__reference">
          <strong>Fenómeno óptico ({{ world().nameEs }}):</strong>
          {{ world().skyOpticalProfile.descriptionEs }}
          <br />
          <span>Referencia: {{ world().skyOpticalProfile.scientificReference }}</span>
        </p>
      } @else {
        <p class="result-banner__reference">
          Hora Solar bloqueada: debes lograr un aterrizaje suave (≤ 2,0 m/s) para desbloquear el
          evento crepuscular.
        </p>
      }

      <div class="result-banner__actions">
        <button
          type="button"
          class="result-banner__btn"
          data-testid="retry-mission-btn"
          (click)="retryRequested.emit()"
        >
          Reintentar
        </button>
        <button
          type="button"
          class="result-banner__btn result-banner__btn--secondary"
          data-testid="change-world-btn"
          (click)="changeWorldRequested.emit()"
        >
          Cambiar mundo
        </button>
      </div>
    </aside>
  `,
})
export class MissionResultBannerComponent {
  readonly world = input.required<CelestialBody>();
  readonly attempt = input.required<MissionAttempt>();

  readonly retryRequested = output<void>();
  readonly changeWorldRequested = output<void>();

  readonly titleText = computed(() => {
    const outcome = this.attempt().outcome;
    if (outcome === 'success') {
      return `Aterrizaje exitoso en ${this.world().nameEs}`;
    }
    if (outcome === 'failedSignalLost') {
      return 'Misión fallida – señal perdida';
    }
    return `Misión fallida en ${this.world().nameEs}`;
  });

  readonly summaryText = computed(() => {
    const currentAttempt = this.attempt();
    const speed =
      currentAttempt.touchdownVelocity !== null
        ? `${Math.abs(currentAttempt.touchdownVelocity).toFixed(1)} m/s`
        : 'N/A';
    if (currentAttempt.outcome === 'success') {
      return `Velocidad de contacto: ${speed} (≤ 2,0 m/s) · Combustible restante: ${currentAttempt.remainingFuel.toFixed(0)}% · Hora Solar desbloqueada.`;
    }
    return (
      currentAttempt.failureReasonEs ??
      `Velocidad de impacto (${speed}) superior al umbral seguro de 2,0 m/s.`
    );
  });
}
