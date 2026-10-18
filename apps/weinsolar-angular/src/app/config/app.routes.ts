import { Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('../UI/pages/simulator/simulator.component').then((m) => m.SimulatorComponent),
  },
  {
    path: '**',
    redirectTo: '',
  },
];
