import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
  selector: 'app-simulator-shell',
  changeDetection: ChangeDetectionStrategy.OnPush,
  styles: [
    `
      .shell {
        position: relative;
        width: 100vw;
        height: 100vh;
        overflow: hidden;
      }
      .shell__canvas-layer {
        position: absolute;
        inset: 0;
        z-index: 1;
      }
      .shell__hud-top {
        position: absolute;
        top: 1rem;
        left: 1rem;
        right: 1rem;
        z-index: 10;
        pointer-events: none;
      }
      .shell__hud-top ::ng-deep * {
        pointer-events: auto;
      }
      .shell__hud-bottom {
        position: absolute;
        bottom: 1.25rem;
        left: 1rem;
        right: 1rem;
        z-index: 10;
        display: flex;
        flex-wrap: wrap;
        align-items: flex-end;
        justify-content: space-between;
        gap: 1rem;
        pointer-events: none;
      }
      .shell__hud-bottom ::ng-deep * {
        pointer-events: auto;
      }
    `,
  ],
  template: `
    <div class="shell" data-testid="simulator-shell">
      <div class="shell__canvas-layer">
        <ng-content select="[slot=scene]" />
      </div>
      <div class="shell__hud-top">
        <ng-content select="[slot=hud-top]" />
      </div>
      <div class="shell__hud-bottom">
        <ng-content select="[slot=hud-bottom]" />
      </div>
    </div>
  `,
})
export class SimulatorShellComponent {}
