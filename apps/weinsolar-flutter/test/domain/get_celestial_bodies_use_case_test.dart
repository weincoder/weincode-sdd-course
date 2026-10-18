import 'package:flutter_test/flutter_test.dart';
import 'package:weinsolar_flutter/domain/models/celestial_body/celestial_body.dart';
import 'package:weinsolar_flutter/domain/models/celestial_body/gateway/celestial_body_gateway.dart';
import 'package:weinsolar_flutter/domain/usecase/get_celestial_bodies_use_case.dart';
import 'package:weinsolar_flutter/infrastructure/driven_adapters/celestial_body_local_adapter.dart';

class _FakeInvalidGateway implements CelestialBodyGateway {
  final List<CelestialBody> bodies;

  _FakeInvalidGateway(this.bodies);

  @override
  Future<List<CelestialBody>> getAll() async => bodies;

  @override
  Future<CelestialBody> getById(CelestialBodyId id) async =>
      bodies.firstWhere((b) => b.id == id);
}

void main() {
  group('GetCelestialBodiesUseCase (RN-01, FR-001, FR-002, FR-016, FR-024, SC-005)', () {
    late CelestialBodyGateway gateway;
    late GetCelestialBodiesUseCase useCase;

    setUp(() {
      gateway = const CelestialBodyLocalAdapter();
      useCase = GetCelestialBodiesUseCase(gateway: gateway);
    });

    test('returns exactly the 4 playable worlds with Spanish names (FR-001, FR-002)', () async {
      final worlds = await useCase.execute();

      expect(worlds.length, 4);
      expect(
        worlds.map((w) => w.id).toList(),
        [
          CelestialBodyId.earth,
          CelestialBodyId.mars,
          CelestialBodyId.moon,
          CelestialBodyId.titan,
        ],
      );
      expect(
        worlds.map((w) => w.nameEs).toList(),
        ['Tierra', 'Marte', 'Luna', 'Titán'],
      );
    });

    test('validates astrophysical constants within < 1% margin (RN-01, SC-005)', () async {
      final earth = await useCase.getById(CelestialBodyId.earth);
      final mars = await useCase.getById(CelestialBodyId.mars);
      final moon = await useCase.getById(CelestialBodyId.moon);
      final titan = await useCase.getById(CelestialBodyId.titan);

      expect(earth.gravity, closeTo(9.81, 9.81 * 0.01));
      expect(earth.atmosphericDensity, closeTo(1.225, 1.225 * 0.01));

      expect(mars.gravity, closeTo(3.71, 3.71 * 0.01));
      expect(mars.atmosphericDensity, closeTo(0.020, 0.020 * 0.01));

      expect(moon.gravity, closeTo(1.62, 1.62 * 0.01));
      expect(moon.atmosphericDensity, 0.0);

      expect(titan.gravity, closeTo(1.352, 1.352 * 0.01));
      expect(titan.atmosphericDensity, closeTo(5.3, 5.3 * 0.01));
    });

    test('enforces ceilingAltitude == 1.5 * initialAltitude and non-empty scientificReference (FR-016, FR-024)', () async {
      final worlds = await useCase.execute();

      for (final world in worlds) {
        expect(world.initialAltitude, 500.0);
        expect(world.ceilingAltitude, world.initialAltitude * 1.5);
        expect(world.ceilingAltitude, 750.0);
        expect(world.scientificReference.trim().isNotEmpty, isTrue);
        expect(world.initialFuel, 100.0);
        expect(world.initialVelocity, lessThan(0.0));
        expect(world.timeScale, greaterThanOrEqualTo(1.0));
      }
    });

    test('throws StateError if gateway returns invalid astrophysical constants violating RN-01', () async {
      final validWorlds = await useCase.execute();
      final corruptedEarth = CelestialBody(
        id: CelestialBodyId.earth,
        nameEs: 'Tierra',
        gravity: 5.0, // Invalid gravity for Earth
        atmosphericDensity: 1.225,
        timeScale: 2.0,
        initialAltitude: 500.0,
        ceilingAltitude: 750.0,
        initialVelocity: -25.0,
        initialFuel: 100.0,
        terrainTheme: validWorlds.first.terrainTheme,
        skyOpticalProfile: validWorlds.first.skyOpticalProfile,
      );

      final invalidUseCase = GetCelestialBodiesUseCase(
        gateway: _FakeInvalidGateway([
          corruptedEarth,
          validWorlds[1],
          validWorlds[2],
          validWorlds[3],
        ]),
      );

      expect(() => invalidUseCase.execute(), throwsA(isA<StateError>()));
    });
  });
}
