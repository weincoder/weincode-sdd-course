import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';
import {
  CelestialBody,
  CelestialBodyId,
} from '../../../domain/models/celestial-body/celestial-body';
import { CelestialBodyGateway } from '../../../domain/models/celestial-body/gateway/celestial-body-gateway';
import { CelestialBodyMapper } from '../../helpers/mappers/celestial-body.mapper';

const RAW_CELESTIAL_BODIES: readonly unknown[] = [
  {
    id: 'earth',
    nameEs: 'Tierra',
    gravity: 9.81,
    atmosphericDensity: 1.225,
    timeScale: 2,
    initialAltitude: 500,
    ceilingAltitude: 750,
    initialVelocity: -25.0,
    initialFuel: 100.0,
    terrainTheme: {
      kind: 'earth-meadow-rocks',
      primarySurfaceHex: '#3B5E34',
      secondarySurfaceHex: '#2E4A28',
      featureColorHex: '#5C6468',
      accentFeatureColorHex: '#4A7A3D',
      landingPadColorHex: '#7A8288',
      landingPadTrimHex: '#C7A336',
    },
    skyOpticalProfile: {
      scientificReference:
        'NASA Earth Observatory — Dispersión molecular de Rayleigh (N₂/O₂, λ⁻⁴)',
      descriptionEs:
        'Dispersión molecular de Rayleigh: cielo azul diurno que se torna naranja intenso y carmesí en el horizonte cuando la luz solar atraviesa mayor espesor atmosférico.',
      shadowHardness: 0.65,
      hasAtmosphere: true,
      keyframes: [
        {
          elevationDeg: -10,
          zenithColorHex: '#020308',
          horizonColorHex: '#090D16',
          sunHaloColorHex: '#1F120E',
          sunDiscColorHex: '#7A2810',
          ambientLightIntensity: 0.08,
        },
        {
          elevationDeg: 0,
          zenithColorHex: '#1B294A',
          horizonColorHex: '#D92B04',
          sunHaloColorHex: '#FF6B1A',
          sunDiscColorHex: '#FF9E44',
          ambientLightIntensity: 0.32,
        },
        {
          elevationDeg: 12,
          zenithColorHex: '#1F3F73',
          horizonColorHex: '#FF5E1A',
          sunHaloColorHex: '#FF8C42',
          sunDiscColorHex: '#FFD27D',
          ambientLightIntensity: 0.5,
        },
        {
          elevationDeg: 35,
          zenithColorHex: '#1E5799',
          horizonColorHex: '#7DB9E8',
          sunHaloColorHex: '#FFF5D6',
          sunDiscColorHex: '#FFFDF4',
          ambientLightIntensity: 0.78,
        },
        {
          elevationDeg: 90,
          zenithColorHex: '#16498C',
          horizonColorHex: '#8AC4F2',
          sunHaloColorHex: '#FFFDF4',
          sunDiscColorHex: '#FFFDF4',
          ambientLightIntensity: 0.9,
        },
      ],
    },
  },
  {
    id: 'mars',
    nameEs: 'Marte',
    gravity: 3.71,
    atmosphericDensity: 0.02,
    timeScale: 3,
    initialAltitude: 500,
    ceilingAltitude: 750,
    initialVelocity: -20.0,
    initialFuel: 100.0,
    terrainTheme: {
      kind: 'mars-regolith-rocks',
      primarySurfaceHex: '#8C442A',
      secondarySurfaceHex: '#6B311D',
      featureColorHex: '#4F2415',
      accentFeatureColorHex: '#B8623E',
      landingPadColorHex: '#6D6764',
      landingPadTrimHex: '#C7A336',
    },
    skyOpticalProfile: {
      scientificReference:
        'NASA Mars Science Laboratory Curiosity — PIA19400 (Sol 956 Gale Crater Sunset)',
      descriptionEs:
        'El polvo fino de óxido de hierro en suspensión tiñe el cielo de ocre cálido de día, pero al atardecer dispersa la luz azul hacia adelante creando un característico halo azul frío alrededor del Sol.',
      shadowHardness: 0.55,
      hasAtmosphere: true,
      keyframes: [
        {
          elevationDeg: -10,
          zenithColorHex: '#1A110E',
          horizonColorHex: '#2A1B16',
          sunHaloColorHex: '#253545',
          sunDiscColorHex: '#6C93B8',
          ambientLightIntensity: 0.06,
        },
        {
          elevationDeg: 0,
          zenithColorHex: '#593A30',
          horizonColorHex: '#6E473B',
          sunHaloColorHex: '#6C93B8',
          sunDiscColorHex: '#BDD9F2',
          ambientLightIntensity: 0.28,
        },
        {
          elevationDeg: 12,
          zenithColorHex: '#6E473B',
          horizonColorHex: '#8A5642',
          sunHaloColorHex: '#8FB8DE',
          sunDiscColorHex: '#D8ECFF',
          ambientLightIntensity: 0.42,
        },
        {
          elevationDeg: 30,
          zenithColorHex: '#C67D50',
          horizonColorHex: '#E2A878',
          sunHaloColorHex: '#EDD0B4',
          sunDiscColorHex: '#FFF5E8',
          ambientLightIntensity: 0.62,
        },
        {
          elevationDeg: 90,
          zenithColorHex: '#B86D43',
          horizonColorHex: '#E5B085',
          sunHaloColorHex: '#F5DEC6',
          sunDiscColorHex: '#FFF5E8',
          ambientLightIntensity: 0.72,
        },
      ],
    },
  },
  {
    id: 'moon',
    nameEs: 'Luna',
    gravity: 1.62,
    atmosphericDensity: 0.0,
    timeScale: 4,
    initialAltitude: 500,
    ceilingAltitude: 750,
    initialVelocity: -15.0,
    initialFuel: 100.0,
    terrainTheme: {
      kind: 'moon-craters',
      primarySurfaceHex: '#73767A',
      secondarySurfaceHex: '#525558',
      featureColorHex: '#3B3D40',
      accentFeatureColorHex: '#92959A',
      landingPadColorHex: '#686A6E',
      landingPadTrimHex: '#C7A336',
    },
    skyOpticalProfile: {
      scientificReference:
        'NASA Apollo 11–17 Surface Photography & Lunar Reconnaissance Orbiter (LRO) — Exosfera en vacío (ρ = 0)',
      descriptionEs:
        'Sin atmósfera que disperse los fotones solares, el cielo permanece negro absoluto a cualquier hora solar y las sombras proyectadas sobre el regolito son completamente negras y de borde duro.',
      shadowHardness: 1.0,
      hasAtmosphere: false,
      keyframes: [
        {
          elevationDeg: -10,
          zenithColorHex: '#000000',
          horizonColorHex: '#000000',
          sunHaloColorHex: '#000000',
          sunDiscColorHex: '#000000',
          ambientLightIntensity: 0.0,
        },
        {
          elevationDeg: 0,
          zenithColorHex: '#000000',
          horizonColorHex: '#000000',
          sunHaloColorHex: '#000000',
          sunDiscColorHex: '#FFFDF8',
          ambientLightIntensity: 0.0,
        },
        {
          elevationDeg: 90,
          zenithColorHex: '#000000',
          horizonColorHex: '#000000',
          sunHaloColorHex: '#000000',
          sunDiscColorHex: '#FFFDF8',
          ambientLightIntensity: 0.0,
        },
      ],
    },
  },
  {
    id: 'titan',
    nameEs: 'Titán',
    gravity: 1.352,
    atmosphericDensity: 5.3,
    timeScale: 4,
    initialAltitude: 500,
    ceilingAltitude: 750,
    initialVelocity: -12.0,
    initialFuel: 100.0,
    terrainTheme: {
      kind: 'titan-icy-haze',
      primarySurfaceHex: '#6F4922',
      secondarySurfaceHex: '#523415',
      featureColorHex: '#84603C',
      accentFeatureColorHex: '#9A7248',
      landingPadColorHex: '#6A5B4C',
      landingPadTrimHex: '#C7A336',
    },
    skyOpticalProfile: {
      scientificReference:
        'ESA/NASA/JPL-Caltech Cassini-Huygens DISR Surface Images (14 enero 2005)',
      descriptionEs:
        'Una densa atmósfera de nitrógeno y aerosoles orgánicos (tolinas) a 5,3 kg/m³ envuelve la superficie en una bruma ámbar anaranjada con iluminación difusa y sombras casi imperceptibles.',
      shadowHardness: 0.15,
      hasAtmosphere: true,
      keyframes: [
        {
          elevationDeg: -10,
          zenithColorHex: '#120702',
          horizonColorHex: '#1F0C04',
          sunHaloColorHex: '#2B1105',
          sunDiscColorHex: '#3D1A05',
          ambientLightIntensity: 0.08,
        },
        {
          elevationDeg: 0,
          zenithColorHex: '#3D1A05',
          horizonColorHex: '#6E320C',
          sunHaloColorHex: '#8C4312',
          sunDiscColorHex: '#B85D19',
          ambientLightIntensity: 0.22,
        },
        {
          elevationDeg: 18,
          zenithColorHex: '#6E320C',
          horizonColorHex: '#A65118',
          sunHaloColorHex: '#C46A23',
          sunDiscColorHex: '#DF8B3B',
          ambientLightIntensity: 0.34,
        },
        {
          elevationDeg: 90,
          zenithColorHex: '#B85D19',
          horizonColorHex: '#D9822B',
          sunHaloColorHex: '#E39844',
          sunDiscColorHex: '#F0AE5E',
          ambientLightIntensity: 0.48,
        },
      ],
    },
  },
];

@Injectable({ providedIn: 'root' })
export class CelestialBodyLocalAdapter extends CelestialBodyGateway {
  private readonly catalog: readonly CelestialBody[] = RAW_CELESTIAL_BODIES.map((item) =>
    CelestialBodyMapper.fromRaw(item),
  );

  getAll(): Observable<CelestialBody[]> {
    return of([...this.catalog]);
  }

  getById(id: CelestialBodyId): Observable<CelestialBody> {
    const found = this.catalog.find((item) => item.id === id);
    if (!found) {
      throw new Error(`CelestialBody with id "${id}" not found in local catalog.`);
    }
    return of(found);
  }
}
