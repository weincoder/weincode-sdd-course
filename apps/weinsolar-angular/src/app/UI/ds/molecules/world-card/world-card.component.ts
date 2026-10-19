import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { CelestialBody } from '../../../../domain/models/celestial-body/celestial-body';

@Component({
  selector: 'app-world-card',
  changeDetection: ChangeDetectionStrategy.OnPush,
  styles: [
    `
      .world-card {
        display: flex;
        flex-direction: column;
        justify-content: space-between;
        gap: 0.75rem;
        padding: 1.25rem;
        background-color: #18084D;
        border: 2px solid #A599FF;
        border-radius: 0.85rem;
        color: #FFFFFF;
        text-align: left;
        cursor: pointer;
        width: 100%;
        transition: border-color 140ms ease, background-color 140ms ease;
      }
      .world-card:hover,
      .world-card:focus-visible {
        border-color: #5236FF;
        outline: none;
      }
      .world-card__header {
        display: flex;
        align-items: baseline;
        justify-content: space-between;
        gap: 0.5rem;
      }
      .world-card__title {
        font-size: 1.35rem;
        font-weight: 800;
        color: #FFFFFF;
      }
      .world-card__scale {
        font-size: 0.78rem;
        font-weight: 700;
        color: #FFFFFF;
        background-color: #5236FF;
        padding: 0.2rem 0.55rem;
        border-radius: 999px;
      }
      .world-card__metrics {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 0.5rem;
      }
      .world-card__metric-label {
        font-size: 0.7rem;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        color: #A599FF;
        display: block;
      }
      .world-card__metric-value {
        font-size: 0.98rem;
        font-weight: 700;
        color: #FFFFFF;
      }
      .world-card__desc {
        font-size: 0.82rem;
        line-height: 1.4;
        color: #A599FF;
      }
      .world-card__cta {
        display: inline-block;
        margin-top: 0.25rem;
        padding: 0.5rem 0.9rem;
        background-color: #5236FF;
        color: #FFFFFF;
        border-radius: 0.5rem;
        font-size: 0.84rem;
        font-weight: 700;
        text-align: center;
      }
    `,
  ],
  template: `
    <button
      type="button"
      class="world-card"
      [attr.data-testid]="'world-card-' + world().id"
      (click)="worldSelected.emit(world())"
    >
      <div class="world-card__header">
        <span class="world-card__title">{{ world().nameEs }}</span>
        <span class="world-card__scale">Escala ×{{ world().timeScale }}</span>
      </div>

      <div class="world-card__metrics">
        <div>
          <span class="world-card__metric-label">Gravedad superficial</span>
          <span class="world-card__metric-value">{{ world().gravity }} m/s²</span>
        </div>
        <div>
          <span class="world-card__metric-label">Densidad atmosférica</span>
          <span class="world-card__metric-value">{{ world().atmosphericDensity }} kg/m³</span>
        </div>
      </div>

      <p class="world-card__desc">{{ world().skyOpticalProfile.descriptionEs }}</p>
      <span class="world-card__cta">Iniciar descenso en {{ world().nameEs }}</span>
    </button>
  `,
})
export class WorldCardComponent {
  readonly world = input.required<CelestialBody>();
  readonly worldSelected = output<CelestialBody>();
}
