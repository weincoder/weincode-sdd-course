enum TerrainFeatureKind {
  rock,
  crater,
  dune,
  iceRidge,
  vegetation,
}

class TerrainFeature {
  final TerrainFeatureKind kind;
  final double x;
  final double z;
  final double radius;
  final double height;
  final double rotationRad;

  const TerrainFeature({
    required this.kind,
    required this.x,
    required this.z,
    required this.radius,
    required this.height,
    required this.rotationRad,
  });
}

class TerrainLayout {
  final double sizeMeters;
  final int resolution;
  final double maxHeightMeters;
  final double padRadiusMeters;
  final List<double> heights;
  final List<TerrainFeature> features;

  const TerrainLayout({
    required this.sizeMeters,
    required this.resolution,
    required this.maxHeightMeters,
    required this.padRadiusMeters,
    required this.heights,
    required this.features,
  });
}
