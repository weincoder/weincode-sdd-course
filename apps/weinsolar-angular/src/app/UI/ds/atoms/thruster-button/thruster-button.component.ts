import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';

@Component({
  selector: 'app-thruster-button',
  changeDetection: ChangeDetectionStrategy.OnPush,
  styles: [
    `
      .thruster-btn {
        display: inline-flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 0.25rem;
        min-width: 13rem;
        padding: 0.85rem 1.5rem;
        background-color: #18084D;
        color: #FFFFFF;
        border: 2px solid #5236FF;
        border-radius: 0.75rem;
        font-size: 0.95rem;
        font-weight: 700;
        letter-spacing: 0.04em;
        cursor: pointer;
        touch-action: none;
        transition: background-color 120ms ease, transform 80ms ease;
      }
      .thruster-btn--active {
        background-color: #5236FF;
        color: #FFFFFF;
        transform: scale(0.98);
      }
      .thruster-btn--disabled {
        border-color: #A599FF;
        color: #A599FF;
        cursor: not-allowed;
        opacity: 0.75;
      }
      .thruster-btn__hint {
        font-size: 0.72rem;
        font-weight: 500;
        color: #A599FF;
      }
      .thruster-btn--active .thruster-btn__hint {
        color: #FFFFFF;
      }
    `,
  ],
  template: `
    <button
      type="button"
      class="thruster-btn"
      data-testid="thruster-btn"
      [class.thruster-btn--active]="isActive() && !isOutOfFuel()"
      [class.thruster-btn--disabled]="isOutOfFuel() || disabled()"
      [disabled]="isOutOfFuel() || disabled()"
      (pointerdown)="onPressStart($event)"
      (pointerup)="onPressEnd()"
      (pointerleave)="onPressEnd()"
      (pointercancel)="onPressEnd()"
    >
      @if (isOutOfFuel()) {
        <span>SIN COMBUSTIBLE (0%)</span>
        <span class="thruster-btn__hint">Propulsor inactivo</span>
      } @else {
        <span>{{ isActive() ? 'PROPULSOR ACTIVO' : 'ACTIVAR PROPULSOR' }}</span>
        <span class="thruster-btn__hint">Mantener pulsado o Espacio / ↑</span>
      }
    </button>
  `,
})
export class ThrusterButtonComponent {
  readonly isActive = input.required<boolean>();
  readonly isOutOfFuel = input.required<boolean>();
  readonly disabled = input<boolean>(false);

  readonly thrusterChanged = output<boolean>();

  onPressStart(event: PointerEvent): void {
    event.preventDefault();
    if (this.isOutOfFuel() || this.disabled()) {
      return;
    }
    this.thrusterChanged.emit(true);
  }

  onPressEnd(): void {
    if (this.isActive()) {
      this.thrusterChanged.emit(false);
    }
  }
}
