import { ChangeDetectionStrategy, Component, input } from '@angular/core';

@Component({
  selector: 'app-telemetry-badge',
  changeDetection: ChangeDetectionStrategy.OnPush,
  styles: [
    `
      .badge {
        display: flex;
        flex-direction: column;
        gap: 0.2rem;
        padding: 0.55rem 0.85rem;
        background-color: #18084D;
        border: 1px solid #A599FF;
        border-radius: 0.5rem;
        min-width: 7.5rem;
      }
      .badge--highlight {
        border: 2px solid #5236FF;
        box-shadow: 0 0 0 1px #5236FF;
      }
      .badge__label {
        font-size: 0.7rem;
        letter-spacing: 0.06em;
        text-transform: uppercase;
        color: #A599FF;
        font-weight: 600;
      }
      .badge__value {
        font-size: 1.05rem;
        font-weight: 700;
        color: #FFFFFF;
        font-variant-numeric: tabular-nums;
      }
      .badge__subtext {
        font-size: 0.72rem;
        color: #A599FF;
        font-weight: 600;
      }
      .badge--highlight .badge__subtext {
        color: #FFFFFF;
      }
    `,
  ],
  template: `
    <div class="badge" [class.badge--highlight]="highlighted()">
      <span class="badge__label">{{ label() }}</span>
      <span class="badge__value">{{ value() }}</span>
      @if (subtext(); as sub) {
        <span class="badge__subtext">{{ sub }}</span>
      }
    </div>
  `,
})
export class TelemetryBadgeComponent {
  readonly label = input.required<string>();
  readonly value = input.required<string>();
  readonly subtext = input<string>('');
  readonly highlighted = input<boolean>(false);
}
