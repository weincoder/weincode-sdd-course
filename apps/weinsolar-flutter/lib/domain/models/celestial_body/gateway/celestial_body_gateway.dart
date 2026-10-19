import '../celestial_body.dart';

abstract class CelestialBodyGateway {
  Future<List<CelestialBody>> getAll();
  Future<CelestialBody> getById(CelestialBodyId id);
}
