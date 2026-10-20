import 'dart:math' as math;

import '../models/celestial_body/celestial_body.dart';
import '../models/scene/terrain_layout.dart';
import '../models/scene/visual_quality.dart';

class _Mulberry32 {
  int _state;

  _Mulberry32(int seed) : _state = seed & 0xFFFFFFFF;

  double nextDouble() {
    _state = (_state + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _imul32(_state ^ (_state >>> 15), 1 | _state);
    t = (t + _imul32(t ^ (t >>> 7), 61 | t)) ^ t;
    t = (t ^ (t >>> 14)) & 0xFFFFFFFF;
    return t / 4294967296.0;
  }

  static int _imul32(int a, int b) {
    final aHi = (a >>> 16) & 0xFFFF;
    final aLo = a & 0xFFFF;
    final bHi = (b >>> 16) & 0xFFFF;
    final bLo = b & 0xFFFF;
    return ((aLo * bLo) + (((aHi * bLo + aLo * bHi) & 0xFFFF) << 16)) &
        0xFFFFFFFF;
  }
}

class GenerateTerrainLayoutUseCase {
  static const double terrainSizeMeters = 600.0;
  static const double padRadiusMeters = 6.0;
  static const double padPlainRadiusMeters = 65.0;

  static const Map<CelestialBodyId, int> _worldSeeds = {
    CelestialBodyId.earth: 0x1A2B3C4D,
    CelestialBodyId.mars: 0x2B3C4D5E,
    CelestialBodyId.moon: 0x3C4D5E6F,
    CelestialBodyId.titan: 0x4D5E6F70,
  };

  static const Map<CelestialBodyId, double> _worldMaxHeights = {
    CelestialBodyId.earth: 18.0,
    CelestialBodyId.mars: 22.0,
    CelestialBodyId.moon: 16.0,
    CelestialBodyId.titan: 14.0,
  };

  final Map<String, TerrainLayout> _cache = {};

  GenerateTerrainLayoutUseCase();

  TerrainLayout execute(CelestialBody world, VisualQuality quality) {
    final cacheKey = '${world.id.name}:${quality.name}';
    final cached = _cache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final resolution = quality == VisualQuality.high ? 192 : 64;
    final maxHeightMeters = _worldMaxHeights[world.id] ?? 18.0;
    final seed = _worldSeeds[world.id] ?? 0x1A2B3C4D;

    final allFeatures = _generateCanonicalFeatures(world.id, seed);
    final featureCount = quality == VisualQuality.high
        ? allFeatures.length
        : (allFeatures.length * 0.4).round();
    final features = allFeatures.sublist(0, featureCount);

    final heights = List<double>.filled(resolution * resolution, 0.0);
    const half = terrainSizeMeters / 2.0;

    for (var row = 0; row < resolution; row++) {
      final z = -half + (row / (resolution - 1)) * terrainSizeMeters;
      for (var col = 0; col < resolution; col++) {
        final x = -half + (col / (resolution - 1)) * terrainSizeMeters;
        final distFromCenter = math.sqrt(x * x + z * z);

        if (distFromCenter <= padRadiusMeters) {
          heights[row * resolution + col] = 0.0;
          continue;
        }

        final nearPadBlend = _smoothstep(padRadiusMeters, 22.0, distFromCenter);
        final distantHillsBlend = _smoothstep(
          28.0,
          padPlainRadiusMeters * 2.2,
          distFromCenter,
        );

        final baseNoise = _fbmNoise(x + 300.0, z + 300.0, seed);
        final microRelief =
            (_valueNoise2d(x * 0.08, z * 0.08, seed + 777) - 0.5) * 0.65;
        var rawH = microRelief * nearPadBlend +
            math.max(0.0, baseNoise - 0.34) *
                maxHeightMeters *
                1.15 *
                distantHillsBlend;

        if (world.id == CelestialBodyId.mars) {
          final duneWave =
              math.sin(x * 0.032 + z * 0.018) * 1.6 * distantHillsBlend;
          rawH += duneWave;
        } else if (world.id == CelestialBodyId.titan) {
          final ridge = (math.sin(x * 0.022 - z * 0.026)).abs() *
              3.4 *
              distantHillsBlend;
          rawH += ridge;
        } else if (world.id == CelestialBodyId.moon) {
          for (final feat in features) {
            if (feat.kind == TerrainFeatureKind.crater) {
              final dx = x - feat.x;
              final dz = z - feat.z;
              final r = math.sqrt(dx * dx + dz * dz) / feat.radius;
              if (r < 1.0) {
                rawH -= (1.0 - r * r) * feat.height * 0.45 * nearPadBlend;
              } else if (r < 1.35) {
                final rimT = 1.0 - (r - 1.15).abs() / 0.2;
                rawH += math.max(0.0, rimT) * feat.height * 0.28 * nearPadBlend;
              }
            }
          }
        }

        heights[row * resolution + col] =
            math.min(maxHeightMeters, rawH * nearPadBlend);
      }
    }

    final layout = TerrainLayout(
      sizeMeters: terrainSizeMeters,
      resolution: resolution,
      maxHeightMeters: maxHeightMeters,
      padRadiusMeters: padRadiusMeters,
      heights: List<double>.unmodifiable(heights),
      features: List<TerrainFeature>.unmodifiable(features),
    );

    _cache[cacheKey] = layout;
    return layout;
  }

  List<TerrainFeature> _generateCanonicalFeatures(
    CelestialBodyId worldId,
    int seed,
  ) {
    final prng = _Mulberry32(seed ^ 0x9E3779B9);
    const totalCount = 30;
    final list = <TerrainFeature>[];

    for (var i = 0; i < totalCount; i++) {
      final angle = prng.nextDouble() * math.pi * 2.0;
      final distance = 20.0 + prng.nextDouble() * 200.0;
      final x = math.cos(angle) * distance;
      final z = math.sin(angle) * distance;
      final radius = 1.6 + prng.nextDouble() * 5.4;
      final height = 1.2 + prng.nextDouble() * 4.8;
      final rotationRad = prng.nextDouble() * math.pi * 2.0;

      final TerrainFeatureKind kind;
      switch (worldId) {
        case CelestialBodyId.earth:
          kind = i.isEven
              ? TerrainFeatureKind.rock
              : TerrainFeatureKind.vegetation;
        case CelestialBodyId.mars:
          kind =
              i % 3 == 0 ? TerrainFeatureKind.dune : TerrainFeatureKind.rock;
        case CelestialBodyId.moon:
          kind =
              i % 4 == 0 ? TerrainFeatureKind.rock : TerrainFeatureKind.crater;
        case CelestialBodyId.titan:
          kind = i % 3 == 0
              ? TerrainFeatureKind.rock
              : TerrainFeatureKind.iceRidge;
      }

      list.add(
        TerrainFeature(
          kind: kind,
          x: x,
          z: z,
          radius: radius,
          height: height,
          rotationRad: rotationRad,
        ),
      );
    }

    return list;
  }

  static double _smoothstep(double edge0, double edge1, double x) {
    final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
  }

  static double _hash2d(int ix, int iz, int seed) {
    var h = (ix * 374761393 + iz * 668265263 + seed * 1442695041) & 0xFFFFFFFF;
    h = _Mulberry32._imul32(h ^ (h >>> 13), 1274126177);
    return ((h ^ (h >>> 16)) & 0xFFFFFFFF) / 4294967296.0;
  }

  static double _valueNoise2d(double x, double z, int seed) {
    final xi = x.floor();
    final zi = z.floor();
    final xf = x - xi;
    final zf = z - zi;
    final u = xf * xf * (3.0 - 2.0 * xf);
    final v = zf * zf * (3.0 - 2.0 * zf);

    final v00 = _hash2d(xi, zi, seed);
    final v10 = _hash2d(xi + 1, zi, seed);
    final v01 = _hash2d(xi, zi + 1, seed);
    final v11 = _hash2d(xi + 1, zi + 1, seed);

    final x0 = v00 + (v10 - v00) * u;
    final x1 = v01 + (v11 - v01) * u;
    return x0 + (x1 - x0) * v;
  }

  static double _fbmNoise(double x, double z, int seed) {
    var sum = 0.0;
    var amp = 0.52;
    var freq = 0.012;
    for (var o = 0; o < 4; o++) {
      sum += _valueNoise2d(x * freq, z * freq, seed + o * 101) * amp;
      amp *= 0.5;
      freq *= 2.1;
    }
    return sum;
  }
}
