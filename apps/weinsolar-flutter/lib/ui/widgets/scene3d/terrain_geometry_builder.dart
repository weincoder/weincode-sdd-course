import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../../../domain/models/celestial_body/celestial_body.dart';
import '../../../domain/models/scene/terrain_layout.dart';

class TerrainGeometryBuilder {
  static Node build({
    required TerrainLayout layout,
    required TerrainTheme theme,
  }) {
    final root = Node(name: 'Terrain_Root');

    final heightfieldNode = _buildHeightfieldNode(layout: layout, theme: theme);
    root.add(heightfieldNode);

    final padRimNode = _buildLandingPadRimNode(
      padRadiusMeters: layout.padRadiusMeters,
      theme: theme,
    );
    root.add(padRimNode);

    final beaconsNode = _buildPadBeaconsNode(
      padRadiusMeters: layout.padRadiusMeters,
    );
    root.add(beaconsNode);

    final featuresNode = _buildFeaturesNode(layout: layout, theme: theme);
    root.add(featuresNode);

    final referencePostNode = _buildReferencePostNode(
      padRadiusMeters: layout.padRadiusMeters,
      theme: theme,
    );
    root.add(referencePostNode);

    return root;
  }

  static Node _buildHeightfieldNode({
    required TerrainLayout layout,
    required TerrainTheme theme,
  }) {
    // Split the heightfield into a 4x4 grid of spatial chunks (~48 m each)
    // so the camera is never inside a single 597 m bounding box, allowing
    // flutter_scene to fit the near plane cleanly and cull off-screen chunks.
    final res = layout.resolution;
    final stride = res > 96 ? 2 : 1;
    final gridRes = ((res - 1) ~/ stride) + 1;
    final halfSize = layout.sizeMeters * 0.5;
    final step = layout.sizeMeters / (res - 1);

    final baseColor = _parseHexVector4(theme.primarySurfaceHex);
    final secondaryColor = _parseHexVector4(theme.secondaryFeatureHex);
    final padColor = _parseHexVector4(theme.landingPadHex);

    final material = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(1.0, 1.0, 1.0, 1.0)
      ..vertexColorWeight = 1.0
      ..roughnessFactor = 0.88
      ..metallicFactor = 0.06;

    final container = Node(name: 'Terrain_Heightfield');
    const chunkGrid = 4;
    final cellsTotal = gridRes - 1;

    for (var cz = 0; cz < chunkGrid; cz++) {
      final gzStart = (cz * cellsTotal) ~/ chunkGrid;
      final gzEnd = ((cz + 1) * cellsTotal) ~/ chunkGrid;
      final chunkRows = gzEnd - gzStart + 1;

      for (var cx = 0; cx < chunkGrid; cx++) {
        final gxStart = (cx * cellsTotal) ~/ chunkGrid;
        final gxEnd = ((cx + 1) * cellsTotal) ~/ chunkGrid;
        final chunkCols = gxEnd - gxStart + 1;

        final vertexCount = chunkRows * chunkCols;
        final positions = Float32List(vertexCount * 3);
        final colors = Float32List(vertexCount * 4);

        for (var lz = 0; lz < chunkRows; lz++) {
          final gz = gzStart + lz;
          final iz = math.min(res - 1, gz * stride);
          final z = -halfSize + iz * step;

          for (var lx = 0; lx < chunkCols; lx++) {
            final gx = gxStart + lx;
            final ix = math.min(res - 1, gx * stride);
            final x = -halfSize + ix * step;
            final idx = iz * res + ix;
            final outIdx = lz * chunkCols + lx;
            final h = idx < layout.heights.length ? layout.heights[idx] : 0.0;

            final posOffset = outIdx * 3;
            positions[posOffset] = x;
            positions[posOffset + 1] = h;
            positions[posOffset + 2] = z;

            final colOffset = outIdx * 4;
            final r = math.sqrt(x * x + z * z);

            if (r <= 2.1) {
              final scorchMix = 0.45 + (r / 2.1) * 0.55;
              colors[colOffset] = padColor.r * scorchMix;
              colors[colOffset + 1] = padColor.g * scorchMix;
              colors[colOffset + 2] = padColor.b * scorchMix;
              colors[colOffset + 3] = 1.0;
            } else if (r <= layout.padRadiusMeters) {
              final ringDist1 = (r - layout.padRadiusMeters * 0.55).abs();
              final ringDist2 = (r - layout.padRadiusMeters * 0.85).abs();
              final isCrosshair = x.abs() < 0.22 || z.abs() < 0.22;
              if (ringDist1 < 0.28 || ringDist2 < 0.28 || isCrosshair) {
                colors[colOffset] = math.min(1.0, padColor.r * 1.32 + 0.08);
                colors[colOffset + 1] = math.min(1.0, padColor.g * 1.32 + 0.08);
                colors[colOffset + 2] = math.min(1.0, padColor.b * 1.32 + 0.08);
                colors[colOffset + 3] = 1.0;
              } else {
                colors[colOffset] = padColor.r;
                colors[colOffset + 1] = padColor.g;
                colors[colOffset + 2] = padColor.b;
                colors[colOffset + 3] = 1.0;
              }
            } else {
              final hRight = (ix + 1 < res && idx + 1 < layout.heights.length)
                  ? layout.heights[idx + 1]
                  : h;
              final hDown = (iz + 1 < res && idx + res < layout.heights.length)
                  ? layout.heights[idx + res]
                  : h;
              final slope =
                  math.sqrt(math.pow(hRight - h, 2) + math.pow(hDown - h, 2)) /
                      math.max(0.5, step);

              final grain = math.sin(x * 0.35 + z * 0.29) * 0.08 +
                  math.cos(x * 0.14 - z * 0.19) * 0.08 +
                  math.sin((x * x + z * z) * 0.008) * 0.05;

              final heightRatio = layout.maxHeightMeters > 0.0
                  ? ((h + 0.8) / (layout.maxHeightMeters * 0.65) +
                          slope * 0.35 +
                          grain)
                      .clamp(0.0, 1.0)
                  : (0.25 + grain).clamp(0.0, 1.0);

              final crestBoost = h > layout.maxHeightMeters * 0.45 ? 1.12 : 1.0;
              final troughShade = h < -0.15 ? 0.82 : 1.0;
              final shade = crestBoost * troughShade;

              colors[colOffset] = ((baseColor.r +
                          (secondaryColor.r - baseColor.r) * heightRatio) *
                      shade)
                  .clamp(0.0, 1.0);
              colors[colOffset + 1] = ((baseColor.g +
                          (secondaryColor.g - baseColor.g) * heightRatio) *
                      shade)
                  .clamp(0.0, 1.0);
              colors[colOffset + 2] = ((baseColor.b +
                          (secondaryColor.b - baseColor.b) * heightRatio) *
                      shade)
                  .clamp(0.0, 1.0);
              colors[colOffset + 3] = 1.0;
            }
          }
        }

        final indices = <int>[];
        for (var lz = 0; lz < chunkRows - 1; lz++) {
          for (var lx = 0; lx < chunkCols - 1; lx++) {
            final topLeft = lz * chunkCols + lx;
            final topRight = topLeft + 1;
            final bottomLeft = (lz + 1) * chunkCols + lx;
            final bottomRight = bottomLeft + 1;

            indices
              ..add(topLeft)
              ..add(bottomLeft)
              ..add(topRight)
              ..add(topRight)
              ..add(bottomLeft)
              ..add(bottomRight);
          }
        }

        final geometry = MeshGeometry.fromArrays(
          positions: positions,
          colors: colors,
          indices: indices,
        );

        final chunkNode = Node(
          name: 'Terrain_Chunk_${cz}_$cx',
          mesh: Mesh.primitives(
            primitives: [MeshPrimitive(geometry, material)],
          ),
        )..shadowCastingMode = ShadowCastingMode.off;

        container.add(chunkNode);
      }
    }

    return container;
  }

  static Node _buildLandingPadRimNode({
    required double padRadiusMeters,
    required TerrainTheme theme,
  }) {
    final rimGeo = TorusGeometry(
      radius: padRadiusMeters - 0.12,
      tubeRadius: 0.16,
      radialSegments: 36,
      tubularSegments: 12,
    );
    final rimMat = PhysicallyBasedMaterial()
      ..baseColorFactor = _parseHexVector4(theme.landingPadHex)
      ..roughnessFactor = 0.38
      ..metallicFactor = 0.62;

    return Node(
      name: 'Landing_Pad_Rim',
      mesh: Mesh(rimGeo, rimMat),
    )
      ..position = vm.Vector3(0.0, 0.08, 0.0)
      ..shadowStatic = true
      ..shadowCastingMode = ShadowCastingMode.on;
  }

  static Node _buildPadBeaconsNode({required double padRadiusMeters}) {
    final container = Node(name: 'Landing_Pad_Beacons');
    final beaconGeo = SphereGeometry(radius: 0.18, rings: 8, segments: 12);
    final beaconMat = UnlitMaterial()
      ..baseColorFactor = vm.Vector4(0.22, 0.92, 1.0, 1.0);
    final r = padRadiusMeters - 0.12;
    const angles = <double>[0.0, math.pi * 0.5, math.pi, math.pi * 1.5];

    for (var i = 0; i < angles.length; i++) {
      final a = angles[i];
      final node = Node(
        name: 'Pad_Beacon_$i',
        mesh: Mesh(beaconGeo, beaconMat),
      )
        ..position = vm.Vector3(math.cos(a) * r, 0.22, math.sin(a) * r)
        ..shadowCastingMode = ShadowCastingMode.off;
      container.add(node);
    }
    return container;
  }

  static double _sampleTerrainHeight(
    TerrainLayout layout,
    double x,
    double z,
  ) {
    final res = layout.resolution;
    if (res < 2 || layout.heights.isEmpty) {
      return 0.0;
    }
    final halfSize = layout.sizeMeters * 0.5;
    final u = ((x + halfSize) / layout.sizeMeters).clamp(0.0, 1.0);
    final v = ((z + halfSize) / layout.sizeMeters).clamp(0.0, 1.0);
    final ix = (u * (res - 1)).round().clamp(0, res - 1);
    final iz = (v * (res - 1)).round().clamp(0, res - 1);
    final idx = iz * res + ix;
    return idx < layout.heights.length ? layout.heights[idx] : 0.0;
  }

  static Node _buildFeaturesNode({
    required TerrainLayout layout,
    required TerrainTheme theme,
  }) {
    final container = Node(name: 'Terrain_Features');
    final featureColor = _parseHexVector4(theme.secondaryFeatureHex);
    final material = PhysicallyBasedMaterial()
      ..baseColorFactor = featureColor
      ..roughnessFactor = 0.82
      ..metallicFactor = 0.10;

    final rockGeo = IcosphereGeometry(radius: 1.0, subdivisions: 1);
    final craterGeo = TorusGeometry(
      radius: 1.0,
      tubeRadius: 0.22,
      radialSegments: 24,
      tubularSegments: 10,
    );
    final iceRidgeGeo = CuboidGeometry(vm.Vector3(2.2, 0.95, 1.1));
    final vegetationGeo = CylinderGeometry(
      bottomRadius: 0.65,
      topRadius: 0.08,
      height: 2.2,
      radialSegments: 8,
    );
    final duneGeo = SphereGeometry(radius: 1.0, rings: 8, segments: 12);

    for (var i = 0; i < layout.features.length; i++) {
      final f = layout.features[i];
      final groundY = _sampleTerrainHeight(layout, f.x, f.z);
      final Geometry geo;
      late final vm.Vector3 scaleVec;
      late final double yOffset;

      switch (f.kind) {
        case TerrainFeatureKind.rock:
          geo = rockGeo;
          scaleVec = vm.Vector3(f.radius, f.height * 0.75, f.radius * 0.85);
          yOffset = groundY + f.height * 0.28;
        case TerrainFeatureKind.crater:
          geo = craterGeo;
          scaleVec = vm.Vector3(f.radius, f.height * 0.55, f.radius);
          yOffset = groundY + 0.08;
        case TerrainFeatureKind.iceRidge:
          geo = iceRidgeGeo;
          scaleVec = vm.Vector3(f.radius * 0.9, f.height, f.radius * 0.65);
          yOffset = groundY + f.height * 0.35;
        case TerrainFeatureKind.vegetation:
          geo = vegetationGeo;
          scaleVec = vm.Vector3(f.radius * 0.65, f.height * 0.6, f.radius * 0.65);
          yOffset = groundY + f.height * 0.5;
        case TerrainFeatureKind.dune:
          geo = duneGeo;
          scaleVec = vm.Vector3(f.radius * 1.4, f.height * 0.38, f.radius * 0.85);
          yOffset = groundY + f.height * 0.12;
      }

      final node = Node(
        name: 'Feature_${f.kind.name}_$i',
        mesh: Mesh(geo, material),
      )
        ..position = vm.Vector3(f.x, yOffset, f.z)
        ..scale = scaleVec
        ..rotation = vm.Quaternion.axisAngle(
          vm.Vector3(0.0, 1.0, 0.0),
          f.rotationRad,
        )
        ..shadowStatic = true
        ..shadowCastingMode = ShadowCastingMode.on;

      container.add(node);
    }

    return container;
  }

  static Node _buildReferencePostNode({
    required double padRadiusMeters,
    required TerrainTheme theme,
  }) {
    final mastRoot = Node(name: 'Reference_Post_2m')
      ..position = vm.Vector3(padRadiusMeters + 1.5, 0.0, 0.0);

    final postGeometry = CylinderGeometry(
      bottomRadius: 0.07,
      topRadius: 0.06,
      height: 2.0,
      radialSegments: 12,
    );
    final postMaterial = PhysicallyBasedMaterial()
      ..baseColorFactor = _parseHexVector4(theme.landingPadHex)
      ..roughnessFactor = 0.38
      ..metallicFactor = 0.72;

    final shaftNode = Node(
      name: 'Reference_Post_Shaft',
      mesh: Mesh(postGeometry, postMaterial),
    )
      ..position = vm.Vector3(0.0, 1.0, 0.0)
      ..shadowCastingMode = ShadowCastingMode.on;
    mastRoot.add(shaftNode);

    final beaconGeo = SphereGeometry(radius: 0.12, rings: 8, segments: 12);
    final beaconMat = UnlitMaterial()
      ..baseColorFactor = vm.Vector4(1.0, 0.48, 0.18, 1.0);
    final beaconNode = Node(
      name: 'Reference_Post_Beacon',
      mesh: Mesh(beaconGeo, beaconMat),
    )
      ..position = vm.Vector3(0.0, 2.05, 0.0)
      ..shadowCastingMode = ShadowCastingMode.on;
    mastRoot.add(beaconNode);

    return mastRoot;
  }

  static vm.Vector4 _parseHexVector4(String hex) {
    final cleaned = hex.replaceAll('#', '').trim();
    final value = int.tryParse(cleaned, radix: 16) ?? 0x808080;
    final sr = ((value >> 16) & 0xFF) / 255.0;
    final sg = ((value >> 8) & 0xFF) / 255.0;
    final sb = (value & 0xFF) / 255.0;
    return vm.Vector4(
      math.pow(sr, 2.2).toDouble(),
      math.pow(sg, 2.2).toDouble(),
      math.pow(sb, 2.2).toDouble(),
      1.0,
    );
  }
}
