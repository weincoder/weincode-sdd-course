import '../models/celestial_body/celestial_body.dart';
import '../models/celestial_body/gateway/celestial_body_gateway.dart';

class GetCelestialBodiesUseCase {
  static const Map<CelestialBodyId, double> _referenceGravity = {
    CelestialBodyId.earth: 9.81,
    CelestialBodyId.mars: 3.71,
    CelestialBodyId.moon: 1.62,
    CelestialBodyId.titan: 1.352,
  };

  static const Map<CelestialBodyId, double> _referenceDensity = {
    CelestialBodyId.earth: 1.225,
    CelestialBodyId.mars: 0.020,
    CelestialBodyId.moon: 0.0,
    CelestialBodyId.titan: 5.3,
  };

  final CelestialBodyGateway gateway;

  const GetCelestialBodiesUseCase({required this.gateway});

  Future<List<CelestialBody>> execute() async {
    final bodies = await gateway.getAll();
    if (bodies.length != 4) {
      throw StateError(
        'FR-001 violation: expected exactly 4 playable worlds, got ${bodies.length}.',
      );
    }
    for (final body in bodies) {
      _validateInvariants(body);
    }
    return List<CelestialBody>.unmodifiable(bodies);
  }

  Future<CelestialBody> getById(CelestialBodyId id) async {
    final body = await gateway.getById(id);
    _validateInvariants(body);
    return body;
  }

  void _validateInvariants(CelestialBody body) {
    final refGravity = _referenceGravity[body.id];
    final refDensity = _referenceDensity[body.id];

    if (refGravity == null || refDensity == null) {
      throw StateError('Unknown celestial body id: ${body.id}');
    }

    final gravityDelta = (body.gravity - refGravity).abs() / refGravity;
    if (gravityDelta > 0.01) {
      throw StateError(
        'RN-01 / SC-005 violation for ${body.nameEs}: gravity ${body.gravity} deviates > 1% from $refGravity.',
      );
    }

    if (refDensity == 0.0) {
      if (body.atmosphericDensity != 0.0) {
        throw StateError(
          'RN-01 / RN-02 violation for ${body.nameEs}: atmosphericDensity must be 0.0 in vacuum.',
        );
      }
    } else {
      final densityDelta =
          (body.atmosphericDensity - refDensity).abs() / refDensity;
      if (densityDelta > 0.01) {
        throw StateError(
          'RN-01 / SC-005 violation for ${body.nameEs}: density ${body.atmosphericDensity} deviates > 1% from $refDensity.',
        );
      }
    }

    final expectedCeiling = body.initialAltitude * 1.5;
    if ((body.ceilingAltitude - expectedCeiling).abs() > 1e-6) {
      throw StateError(
        'FR-024 violation for ${body.nameEs}: ceilingAltitude must be 1.5 * initialAltitude.',
      );
    }

    if (body.scientificReference.trim().isEmpty) {
      throw StateError(
        'FR-016 violation for ${body.nameEs}: scientificReference must not be empty.',
      );
    }
  }
}
