import '../../domain/models/celestial_body/celestial_body.dart';
import '../../domain/models/celestial_body/gateway/celestial_body_gateway.dart';
import '../helpers/mappers/celestial_body_mapper.dart';

class CelestialBodyLocalAdapter implements CelestialBodyGateway {
  static const String _earthRef =
      'NASA Earth Observatory — Dispersión molecular de Rayleigh (azul diurno a naranja/rojo en ocaso).';
  static const String _marsRef =
      'NASA Mars Science Laboratory Curiosity — PIA19400 (Sol 956 Gale Crater sunset: cielo ocre con halo azul frío por polvo fino).';
  static const String _moonRef =
      'NASA Apollo 11–17 Surface Photography & LRO — Ausencia de atmósfera (ρ = 0), cielo negro permanente (#000000) y corte abrupto en horizonte.';
  static const String _titanRef =
      'ESA/NASA/JPL-Caltech Huygens DISR Surface Images (14 enero 2005) — Bruma densa ámbar/anaranjada de tolinas orgánicas y oscurecimiento difuso.';

  static const List<Map<String, dynamic>> _rawCatalog = [
    {
      'id': 'earth',
      'nameEs': 'Tierra',
      'gravity': 9.81,
      'atmosphericDensity': 1.225,
      'timeScale': 2.0,
      'initialAltitude': 500.0,
      'ceilingAltitude': 750.0,
      'initialVelocity': -25.0,
      'initialFuel': 100.0,
      'terrainTheme': {
        'primarySurfaceHex': '#3D6B48',
        'secondaryFeatureHex': '#5C5346',
        'landingPadHex': '#7A8288',
        'featureType': 'vegetation_rocks',
      },
      'skyOpticalProfile': {
        'scientificReference': _earthRef,
        'dayZenithHex': '#1E5799',
        'dayHorizonHex': '#7DB9E8',
        'sunsetZenithHex': '#165A66',
        'sunsetHorizonHex': '#FF5E1A',
        'nightZenithHex': '#02120E',
        'nightHorizonHex': '#090D16',
        'sunHaloHex': '#FF8C42',
      },
      'lightingProfile': {
        'sunAzimuthDeg': 250.0,
        'sunColorDayHex': '#FFF4E0',
        'sunColorSunsetHex': '#FF7A2E',
        'ambientDayIntensity': 0.45,
        'twilightFadeDeg': 6.0,
        'shadowSoftness': 0.35,
        'scientificReference': _earthRef,
      },
    },
    {
      'id': 'mars',
      'nameEs': 'Marte',
      'gravity': 3.71,
      'atmosphericDensity': 0.020,
      'timeScale': 3.0,
      'initialAltitude': 500.0,
      'ceilingAltitude': 750.0,
      'initialVelocity': -20.0,
      'initialFuel': 100.0,
      'terrainTheme': {
        'primarySurfaceHex': '#A84A2B',
        'secondaryFeatureHex': '#6E2E1A',
        'landingPadHex': '#8A5A44',
        'featureType': 'red_regolith_rocks',
      },
      'skyOpticalProfile': {
        'scientificReference': _marsRef,
        'dayZenithHex': '#C67D50',
        'dayHorizonHex': '#E2A878',
        'sunsetZenithHex': '#6E473B',
        'sunsetHorizonHex': '#8F624F',
        'nightZenithHex': '#1A110E',
        'nightHorizonHex': '#2A1C17',
        'sunHaloHex': '#6C93B8',
      },
      'lightingProfile': {
        'sunAzimuthDeg': 250.0,
        'sunColorDayHex': '#FFE9D2',
        'sunColorSunsetHex': '#6C93B8',
        'ambientDayIntensity': 0.40,
        'twilightFadeDeg': 8.0,
        'shadowSoftness': 0.45,
        'scientificReference': _marsRef,
      },
    },
    {
      'id': 'moon',
      'nameEs': 'Luna',
      'gravity': 1.62,
      'atmosphericDensity': 0.0,
      'timeScale': 4.0,
      'initialAltitude': 500.0,
      'ceilingAltitude': 750.0,
      'initialVelocity': -15.0,
      'initialFuel': 100.0,
      'terrainTheme': {
        'primarySurfaceHex': '#7C7F82',
        'secondaryFeatureHex': '#4F5256',
        'landingPadHex': '#9DA1A6',
        'featureType': 'craters',
      },
      'skyOpticalProfile': {
        'scientificReference': _moonRef,
        'dayZenithHex': '#000000',
        'dayHorizonHex': '#000000',
        'sunsetZenithHex': '#000000',
        'sunsetHorizonHex': '#000000',
        'nightZenithHex': '#000000',
        'nightHorizonHex': '#000000',
        'sunHaloHex': '#FFF8E7',
      },
      'lightingProfile': {
        'sunAzimuthDeg': 250.0,
        'sunColorDayHex': '#FFF8EE',
        'sunColorSunsetHex': '#FFF8EE',
        'ambientDayIntensity': 0.0,
        'twilightFadeDeg': 0.0,
        'shadowSoftness': 0.0,
        'scientificReference': _moonRef,
      },
    },
    {
      'id': 'titan',
      'nameEs': 'Titán',
      'gravity': 1.352,
      'atmosphericDensity': 5.3,
      'timeScale': 4.0,
      'initialAltitude': 500.0,
      'ceilingAltitude': 750.0,
      'initialVelocity': -12.0,
      'initialFuel': 100.0,
      'terrainTheme': {
        'primarySurfaceHex': '#8C5828',
        'secondaryFeatureHex': '#593616',
        'landingPadHex': '#A67442',
        'featureType': 'icy_haze',
      },
      'skyOpticalProfile': {
        'scientificReference': _titanRef,
        'dayZenithHex': '#B85D19',
        'dayHorizonHex': '#D9822B',
        'sunsetZenithHex': '#6E320C',
        'sunsetHorizonHex': '#3D1A05',
        'nightZenithHex': '#120702',
        'nightHorizonHex': '#1F0D04',
        'sunHaloHex': '#E08A3C',
      },
      'lightingProfile': {
        'sunAzimuthDeg': 250.0,
        'sunColorDayHex': '#E8B070',
        'sunColorSunsetHex': '#B5651D',
        'ambientDayIntensity': 0.70,
        'twilightFadeDeg': 10.0,
        'shadowSoftness': 0.9,
        'scientificReference': _titanRef,
      },
    },
  ];

  const CelestialBodyLocalAdapter();

  @override
  Future<List<CelestialBody>> getAll() async {
    return _rawCatalog.map(celestialBodyDataToEntity).toList(growable: false);
  }

  @override
  Future<CelestialBody> getById(CelestialBodyId id) async {
    final entities = await getAll();
    return entities.firstWhere(
      (body) => body.id == id,
      orElse: () => throw StateError('CelestialBody not found for id: $id'),
    );
  }
}
