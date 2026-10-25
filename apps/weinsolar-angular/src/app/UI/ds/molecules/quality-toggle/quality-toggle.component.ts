import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { VisualQuality } from '../../../../domain/models/scene/visual-quality';

@Component({
  selector: 'app-quality-toggle',
  changeDetection: ChangeDetectionStrategy.OnPush,
  styles: [
    `
      .quality-toggle {
        display: inline-flex;
        align-items: center;
        background-color: #18084D;
        border: 1px solid #A599FF;
        border-radius: 0.5rem;
        padding: 0.15rem;
        gap: 0.2rem;
      }
      .quality-toggle__option {
        padding: 0.3rem 0.65rem;
        border: 1px solid transparent;
        border-radius: 0.35rem;
        background-color: transparent;
        color: #A599FF;
        font-size: 0.76rem;
        font-weight: 700;
        cursor: pointer;
      }
      .quality-toggle__option--active {
        background-color: #5236FF;
        border-color: #FFFFFF;
        color: #FFFFFF;
      }
      .quality-toggle__option:focus-visible {
        outline: 2px solid #FFFFFF;
        outline-offset: 1px;
      }
    `,
  ],
  template: `
    <div
      class="quality-toggle"
      role="radiogroup"
      aria-label="Selector de calidad visual"
      data-testid="quality-toggle"
    >
      <button
        type="button"
        role="radio"
        class="quality-toggle__option"
        [class.quality-toggle__option--active]="value() === 'high'"
        [attr.aria-checked]="value() === 'high'"
        data-testid="quality-option-high"
        (click)="selectQuality('high')"
        (keydown.arrowright)="selectQuality('basic')"
        (keydown.arrowleft)="selectQuality('basic')"
      >
        Calidad: Alta
      </button>
      <button
        type="button"
        role="radio"
        class="quality-toggle__option"
        [class.quality-toggle__option--active]="value() === 'basic'"
        [attr.aria-checked]="value() === 'basic'"
        data-testid="quality-option-basic"
        (click)="selectQuality('basic')"
        (keydown.arrowright)="selectQuality('high')"
        (keydown.arrowleft)="selectQuality('high')"
      >
        Calidad: Básica
      </button>
    </div>
  `,
})
export class QualityToggleComponent {
  readonly value = input.required<VisualQuality>();
  readonly valueChange = output<VisualQuality>();

  selectQuality(next: VisualQuality): void {
    if (next !== this.value()) {
      this.valueChange.emit(next);
    }
  }
}
