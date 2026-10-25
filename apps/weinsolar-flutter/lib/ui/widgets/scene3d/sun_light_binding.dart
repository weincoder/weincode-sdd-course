import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../../../domain/models/celestial_body/celestial_body.dart';
import '../../../domain/models/scene/scene_lighting_state.dart';
import 'scene_descriptor_mapper.dart';

class _CachedSkyBinding {
  final GradientSkySource skySource;
  final Skybox skybox;
  final SkyEnvironment skyEnvironment;
  double lastBakedElevationDeg = double.nan;
  String lastBakedZenithHex = '';
  CelestialBodyId? builtCompanionWorldId;

  _CachedSkyBinding({
    required this.skySource,
    required this.skybox,
    required this.skyEnvironment,
  });
}

class SunLightBinding {
  static const double _sunDistanceMeters = 280.0;
  static const double _companionDistanceMeters = 245.0;
  static const double _starDomeRadiusMeters = 320.0;

  static final Expando<_CachedSkyBinding> _skyCache =
      Expando<_CachedSkyBinding>('weinsolar_sky_cache');

  static void apply({
    required Scene scene,
    required Node sunLightNode,
    required SceneLightingState lighting,
    required SkyOpticalProfile skyProfile,
    required QualitySettings quality,
    CelestialBodyId worldId = CelestialBodyId.earth,
    double landerAltitude = 0.0,
  }) {
    final elevationRad =
        math.max(lighting.solarElevationDeg, 5.0) * math.pi / 180.0;
    final dynamicMaxShadowDistance =
        math.max(80.0, 18.0 / math.tan(elevationRad));

    final useSoftShadows = quality.softShadows && lighting.shadowSoftness > 0.0;

    final travelDirection = vm.Vector3(
      -lighting.sunDirection.x,
      -lighting.sunDirection.y,
      -lighting.sunDirection.z,
    );
    if (travelDirection.length2 > 1e-6) {
      travelDirection.normalize();
    } else {
      travelDirection.setValues(0.0, -1.0, 0.0);
    }

    final isVacuum = lighting.shadowSoftness <= 0.0;
    final isNight = lighting.solarElevationDeg <= 0.5;

    // Provide gentle nocturnal moonlight/planetshine when the sun sets so the
    // spacecraft and terrain remain softly visible under the stars.
    final vm.Vector3 effectiveLightColor;
    final double effectiveLightIntensity;
    if (isNight && worldId == CelestialBodyId.earth) {
      effectiveLightColor = _parseHexLinearVector3('#9EC2FF');
      effectiveLightIntensity = 0.55;
    } else if (isNight && worldId == CelestialBodyId.titan) {
      effectiveLightColor = _parseHexLinearVector3('#E8A864');
      effectiveLightIntensity = 0.42;
    } else if (isNight && worldId == CelestialBodyId.moon) {
      effectiveLightColor = _parseHexLinearVector3('#6CA8FF');
      effectiveLightIntensity = 0.38;
    } else {
      effectiveLightColor = _parseHexLinearVector3(lighting.sunColorHex);
      effectiveLightIntensity =
          math.max(0.18, lighting.sunIntensity * (isVacuum ? 3.4 : 2.8));
    }

    final light = DirectionalLight(
      direction: travelDirection,
      color: effectiveLightColor,
      intensity: effectiveLightIntensity,
      castsShadow: lighting.castsShadows,
      shadowCascadeCount: 1,
      shadowMapResolution: math.min(1024, quality.shadowMapSize),
      shadowMaxDistance: dynamicMaxShadowDistance,
      shadowSoftness: lighting.shadowSoftness * 0.18,
      shadowAmbientStrength: isVacuum ? 1.0 : 0.72,
      shadowFilter: useSoftShadows
          ? DirectionalShadowFilter.pcss
          : DirectionalShadowFilter.fixedPcf,
    );

    scene.directionalLight = light;

    final visualSunDir = _computeVisualSunDirection(lighting);

    final lowAngleFactor =
        ((22.0 - lighting.solarElevationDeg) / 22.0).clamp(0.0, 1.0);
    final nightFactor = lighting.solarElevationDeg < 0.0
        ? (-lighting.solarElevationDeg / 10.0).clamp(0.0, 1.0)
        : 0.0;

    final zenithDay = _parseHexLinearVector3(skyProfile.dayZenithHex);
    final zenithSunset = _parseHexLinearVector3(skyProfile.sunsetZenithHex);
    final zenithNight = _parseHexLinearVector3(skyProfile.nightZenithHex);
    var zenithVec = zenithDay + (zenithSunset - zenithDay) * lowAngleFactor;
    zenithVec = zenithVec + (zenithNight - zenithVec) * nightFactor;

    final horizonDay = _parseHexLinearVector3(skyProfile.dayHorizonHex);
    final horizonSunset = _parseHexLinearVector3(skyProfile.sunsetHorizonHex);
    final horizonNight = _parseHexLinearVector3(skyProfile.nightHorizonHex);
    var horizonVec =
        horizonDay + (horizonSunset - horizonDay) * lowAngleFactor;
    horizonVec = horizonVec + (horizonNight - horizonVec) * nightFactor;

    final groundVec = _parseHexLinearVector3(lighting.ambientGroundColorHex) *
        (0.18 + 0.38 * lighting.sunIntensity);

    final sunDiskHdr = _parseHexLinearVector3(lighting.sunColorHex) *
        (lighting.sunIntensity > 0.01 && lighting.solarElevationDeg >= -3.0
            ? (2.2 + lighting.sunIntensity * 1.8)
            : 0.0);

    var cached = _skyCache[scene];
    if (cached == null) {
      final skySource = GradientSkySource(
        zenithColor: zenithVec,
        horizonColor: horizonVec,
        groundColor: groundVec,
        sunDirection: visualSunDir,
        sunColor: sunDiskHdr,
        sunSharpness: isVacuum ? 1200.0 : 650.0,
      );
      final skybox = Skybox(skySource);
      final skyEnv = SkyEnvironment(
        skySource,
        refresh: SkyEnvironmentRefresh.manual,
        faceResolution: 64,
        equirectWidth: 256,
      );
      cached = _CachedSkyBinding(
        skySource: skySource,
        skybox: skybox,
        skyEnvironment: skyEnv,
      );
      _skyCache[scene] = cached;
    } else {
      cached.skySource
        ..zenithColor = zenithVec
        ..horizonColor = horizonVec
        ..groundColor = groundVec
        ..sunDirection = visualSunDir
        ..sunColor = sunDiskHdr
        ..sunSharpness = isVacuum ? 1200.0 : 650.0;
    }

    // Anchor sunLightNode at (0, altitude, 0) as the celestial sky root
    final alt = math.max(0.0, landerAltitude);
    sunLightNode.visible = true;
    sunLightNode.position = vm.Vector3(0.0, alt, 0.0);

    _syncSunOrbNode(
      sunLightNode: sunLightNode,
      lighting: lighting,
      skyProfile: skyProfile,
      visualSunDir: visualSunDir,
    );

    _syncStarfieldNode(
      sunLightNode: sunLightNode,
      lighting: lighting,
      worldId: worldId,
    );

    _syncCompanionBodyNode(
      sunLightNode: sunLightNode,
      lighting: lighting,
      worldId: worldId,
      cached: cached,
    );

    scene.skybox = cached.skybox;
    if (quality.atmosphericHazeEnabled && !isVacuum) {
      scene.skyEnvironment = cached.skyEnvironment;
      final elevDiff =
          (cached.lastBakedElevationDeg - lighting.solarElevationDeg).abs();
      if (cached.lastBakedElevationDeg.isNaN ||
          elevDiff >= 2.0 ||
          cached.lastBakedZenithHex != skyProfile.dayZenithHex) {
        cached.lastBakedElevationDeg = lighting.solarElevationDeg;
        cached.lastBakedZenithHex = skyProfile.dayZenithHex;
        cached.skyEnvironment.invalidate();
      }
    } else {
      scene.skyEnvironment = null;
    }

    scene.environmentIntensity =
        isVacuum ? 0.08 : (0.24 + lighting.ambientIntensity * 0.55);
  }

  /// Maps the solar elevation into the camera-visible upper sky along the Sun's
  /// true horizontal azimuth so the Sun orb and corona remain visible in the
  /// viewport during both 65° descent and Solar Hour (-10°..90°).
  static vm.Vector3 _computeVisualSunDirection(SceneLightingState lighting) {
    final sx = lighting.sunDirection.x;
    final sz = lighting.sunDirection.z;
    final horizLen = math.sqrt(sx * sx + sz * sz);
    final dirX = horizLen > 1e-5 ? sx / horizLen : -0.9397;
    final dirZ = horizLen > 1e-5 ? sz / horizLen : -0.3420;

    final elev = lighting.solarElevationDeg;
    final double visualElevDeg;
    if (elev >= 0.0) {
      visualElevDeg = 1.5 + 15.0 * math.pow(elev / 90.0, 0.72);
    } else {
      visualElevDeg = elev * 0.8;
    }
    final visualRad = visualElevDeg * math.pi / 180.0;
    final cosV = math.cos(visualRad);
    return vm.Vector3(dirX * cosV, math.sin(visualRad), dirZ * cosV);
  }

  static void _syncSunOrbNode({
    required Node sunLightNode,
    required SceneLightingState lighting,
    required SkyOpticalProfile skyProfile,
    required vm.Vector3 visualSunDir,
  }) {
    var sunGroup = sunLightNode.getChildByName('Sun_Orb_Group');
    if (sunGroup == null) {
      sunGroup = Node(name: 'Sun_Orb_Group');
      sunLightNode.add(sunGroup);
    }

    var discNode = sunGroup.getChildByName('Sun_Disc_Visual');
    var innerHaloNode = sunGroup.getChildByName('Sun_Inner_Halo_Visual');
    var haloNode = sunGroup.getChildByName('Sun_Halo_Visual');

    if (discNode == null) {
      final discGeo = SphereGeometry(radius: 8.5, rings: 16, segments: 24);
      final discMat = UnlitMaterial()
        ..baseColorFactor = _parseHexLinearVector4(
          lighting.sunColorHex,
          1.0,
          boost: 1.35,
        );
      discNode = Node(name: 'Sun_Disc_Visual', mesh: Mesh(discGeo, discMat))
        ..shadowCastingMode = ShadowCastingMode.off;
      sunGroup.add(discNode);
    }

    if (innerHaloNode == null) {
      final innerGeo = SphereGeometry(radius: 15.5, rings: 16, segments: 24);
      final innerMat = UnlitMaterial()
        ..alphaMode = AlphaMode.blend
        ..baseColorFactor = _parseHexLinearVector4(
          lighting.sunColorHex,
          0.42,
          boost: 1.15,
        );
      innerHaloNode = Node(
        name: 'Sun_Inner_Halo_Visual',
        mesh: Mesh(innerGeo, innerMat),
      )..shadowCastingMode = ShadowCastingMode.off;
      sunGroup.add(innerHaloNode);
    }

    if (haloNode == null) {
      final haloGeo = SphereGeometry(radius: 28.0, rings: 16, segments: 24);
      final haloMat = UnlitMaterial()
        ..alphaMode = AlphaMode.blend
        ..baseColorFactor = _parseHexLinearVector4(skyProfile.sunHaloHex, 0.24);
      haloNode = Node(name: 'Sun_Halo_Visual', mesh: Mesh(haloGeo, haloMat))
        ..shadowCastingMode = ShadowCastingMode.off;
      sunGroup.add(haloNode);
    }

    final isVisible =
        lighting.solarElevationDeg >= -5.0 && lighting.sunIntensity > 0.01;
    sunGroup.visible = isVisible;
    if (!isVisible) {
      return;
    }

    sunGroup.position = vm.Vector3(
      visualSunDir.x * _sunDistanceMeters,
      visualSunDir.y * _sunDistanceMeters,
      visualSunDir.z * _sunDistanceMeters,
    );

    final discPrim = discNode.mesh?.primitives.firstOrNull;
    if (discPrim?.material is UnlitMaterial) {
      (discPrim!.material as UnlitMaterial).baseColorFactor =
          _parseHexLinearVector4(lighting.sunColorHex, 1.0, boost: 1.35);
    }

    final innerPrim = innerHaloNode.mesh?.primitives.firstOrNull;
    if (innerPrim?.material is UnlitMaterial) {
      final hasAtm = lighting.shadowSoftness > 0.0;
      (innerPrim!.material as UnlitMaterial).baseColorFactor =
          _parseHexLinearVector4(
        lighting.sunColorHex,
        hasAtm ? 0.42 : 0.18,
        boost: 1.15,
      );
    }

    final haloPrim = haloNode.mesh?.primitives.firstOrNull;
    if (haloPrim?.material is UnlitMaterial) {
      final hasAtm = lighting.shadowSoftness > 0.0;
      haloNode.visible = hasAtm;
      (haloPrim!.material as UnlitMaterial).baseColorFactor =
          _parseHexLinearVector4(skyProfile.sunHaloHex, hasAtm ? 0.28 : 0.0);
    }
  }

  static void _syncStarfieldNode({
    required Node sunLightNode,
    required SceneLightingState lighting,
    required CelestialBodyId worldId,
  }) {
    var starGroup = sunLightNode.getChildByName('Starfield_Visual');
    if (starGroup == null) {
      starGroup = Node(name: 'Starfield_Visual');
      final starMat = UnlitMaterial()
        ..alphaMode = AlphaMode.blend
        ..vertexColorWeight = 1.0
        ..baseColorFactor = vm.Vector4(1.0, 1.0, 1.0, 1.0);
      for (var sector = 0; sector < 4; sector++) {
        final starGeo = _buildStarfieldSectorGeometry(sector);
        final sectorNode = Node(
          name: 'Starfield_Sector_$sector',
          mesh: Mesh.primitives(
            primitives: [MeshPrimitive(starGeo, starMat)],
          ),
        )..shadowCastingMode = ShadowCastingMode.off;
        starGroup.add(sectorNode);
      }
      sunLightNode.add(starGroup);
    }

    // On Moon (no atmosphere), stars are always visible; on Earth, Mars, Titan
    // stars fade in as solar elevation drops below 18° into twilight and night.
    final double starAlpha;
    if (worldId == CelestialBodyId.moon) {
      starAlpha = lighting.solarElevationDeg <= 10.0 ? 1.0 : 0.85;
    } else {
      starAlpha =
          ((18.0 - lighting.solarElevationDeg) / 20.0).clamp(0.0, 1.0);
    }

    starGroup.visible = starAlpha > 0.02;
    if (!starGroup.visible) {
      return;
    }

    final firstSector = starGroup.children.firstOrNull;
    final prim = firstSector?.mesh?.primitives.firstOrNull;
    if (prim?.material is UnlitMaterial) {
      (prim!.material as UnlitMaterial).baseColorFactor =
          vm.Vector4(1.3, 1.3, 1.3, starAlpha);
    }
  }

  static void _syncCompanionBodyNode({
    required Node sunLightNode,
    required SceneLightingState lighting,
    required CelestialBodyId worldId,
    required _CachedSkyBinding cached,
  }) {
    var companionGroup = sunLightNode.getChildByName('Companion_Planet_Group');
    if (companionGroup == null) {
      companionGroup = Node(name: 'Companion_Planet_Group');
      sunLightNode.add(companionGroup);
    }

    if (cached.builtCompanionWorldId != worldId) {
      companionGroup.removeAll();
      cached.builtCompanionWorldId = worldId;

      if (worldId == CelestialBodyId.earth) {
        // Earth night sky -> The Moon (La Luna)
        final moonGeo = _buildProceduralPlanetSphere(
          radius: 10.5,
          rings: 24,
          segments: 32,
          kind: _CompanionKind.moonOnEarth,
        );
        final moonMat = UnlitMaterial()
          ..alphaMode = AlphaMode.blend
          ..vertexColorWeight = 1.0
          ..baseColorFactor = vm.Vector4(1.15, 1.15, 1.2, 1.0);
        final bodyNode = Node(
          name: 'Companion_Body_Visual',
          mesh: Mesh.primitives(
            primitives: [MeshPrimitive(moonGeo, moonMat)],
          ),
        )..shadowCastingMode = ShadowCastingMode.off;

        final haloGeo = SphereGeometry(radius: 16.5, rings: 16, segments: 24);
        final haloMat = UnlitMaterial()
          ..alphaMode = AlphaMode.blend
          ..baseColorFactor = _parseHexLinearVector4('#A8C8FF', 0.22);
        final haloNode = Node(
          name: 'Companion_Halo_Visual',
          mesh: Mesh(haloGeo, haloMat),
        )..shadowCastingMode = ShadowCastingMode.off;

        companionGroup.add(bodyNode);
        companionGroup.add(haloNode);
      } else if (worldId == CelestialBodyId.moon) {
        // Moon sky -> The Earth (La Tierra)
        final earthGeo = _buildProceduralPlanetSphere(
          radius: 14.5,
          rings: 28,
          segments: 36,
          kind: _CompanionKind.earthOnMoon,
        );
        final earthMat = UnlitMaterial()
          ..alphaMode = AlphaMode.blend
          ..vertexColorWeight = 1.0
          ..baseColorFactor = vm.Vector4(1.2, 1.2, 1.25, 1.0);
        final bodyNode = Node(
          name: 'Companion_Body_Visual',
          mesh: Mesh.primitives(
            primitives: [MeshPrimitive(earthGeo, earthMat)],
          ),
        )..shadowCastingMode = ShadowCastingMode.off;

        final haloGeo = SphereGeometry(radius: 19.0, rings: 16, segments: 24);
        final haloMat = UnlitMaterial()
          ..alphaMode = AlphaMode.blend
          ..baseColorFactor = _parseHexLinearVector4('#4DA6FF', 0.26);
        final haloNode = Node(
          name: 'Companion_Halo_Visual',
          mesh: Mesh(haloGeo, haloMat),
        )..shadowCastingMode = ShadowCastingMode.off;

        companionGroup.add(bodyNode);
        companionGroup.add(haloNode);
      } else if (worldId == CelestialBodyId.titan) {
        // Titan sky -> Jupiter (Júpiter) with bands & Great Red Spot
        final jupiterGeo = _buildProceduralPlanetSphere(
          radius: 18.5,
          rings: 28,
          segments: 36,
          kind: _CompanionKind.jupiterOnTitan,
        );
        final jupiterMat = UnlitMaterial()
          ..alphaMode = AlphaMode.blend
          ..vertexColorWeight = 1.0
          ..baseColorFactor = vm.Vector4(1.2, 1.15, 1.1, 1.0);
        final bodyNode = Node(
          name: 'Companion_Body_Visual',
          mesh: Mesh.primitives(
            primitives: [MeshPrimitive(jupiterGeo, jupiterMat)],
          ),
        )..shadowCastingMode = ShadowCastingMode.off;

        final haloGeo = SphereGeometry(radius: 24.5, rings: 16, segments: 24);
        final haloMat = UnlitMaterial()
          ..alphaMode = AlphaMode.blend
          ..baseColorFactor = _parseHexLinearVector4('#E8A050', 0.22);
        final haloNode = Node(
          name: 'Companion_Halo_Visual',
          mesh: Mesh(haloGeo, haloMat),
        )..shadowCastingMode = ShadowCastingMode.off;

        companionGroup.add(bodyNode);
        companionGroup.add(haloNode);
      }
    }

    // Visibility and opacity per world:
    // - Moon -> Earth is always visible in the black lunar sky
    // - Titan -> Jupiter is always visible (brightening in twilight/night)
    // - Earth -> Moon is visible in twilight and night (solarElevationDeg <= 22°)
    double alpha = 0.0;
    if (worldId == CelestialBodyId.moon) {
      alpha = 1.0;
    } else if (worldId == CelestialBodyId.titan) {
      alpha = lighting.solarElevationDeg <= 15.0 ? 1.0 : 0.85;
    } else if (worldId == CelestialBodyId.earth) {
      alpha = ((22.0 - lighting.solarElevationDeg) / 18.0).clamp(0.0, 1.0);
    }

    companionGroup.visible = alpha > 0.02;
    if (!companionGroup.visible) {
      return;
    }

    // Position the companion body at azimuth ~235° (to the left of the Sun in the
    // forward camera view) and elevation ~12.5° so it is framed in the sky
    const companionAzRad = 235.0 * math.pi / 180.0;
    const companionElevRad = 12.5 * math.pi / 180.0;
    final cosE = math.cos(companionElevRad);
    companionGroup.position = vm.Vector3(
      math.sin(companionAzRad) * cosE * _companionDistanceMeters,
      math.sin(companionElevRad) * _companionDistanceMeters,
      math.cos(companionAzRad) * cosE * _companionDistanceMeters,
    );

    final bodyNode = companionGroup.getChildByName('Companion_Body_Visual');
    final bodyPrim = bodyNode?.mesh?.primitives.firstOrNull;
    if (bodyPrim?.material is UnlitMaterial) {
      (bodyPrim!.material as UnlitMaterial).baseColorFactor =
          vm.Vector4(1.2, 1.2, 1.2, alpha);
    }

    final haloNode = companionGroup.getChildByName('Companion_Halo_Visual');
    final haloPrim = haloNode?.mesh?.primitives.firstOrNull;
    if (haloPrim?.material is UnlitMaterial) {
      final baseHalo = worldId == CelestialBodyId.moon
          ? _parseHexLinearVector3('#4DA6FF')
          : worldId == CelestialBodyId.titan
              ? _parseHexLinearVector3('#E8A050')
              : _parseHexLinearVector3('#A8C8FF');
      (haloPrim!.material as UnlitMaterial).baseColorFactor =
          vm.Vector4(baseHalo.r, baseHalo.g, baseHalo.b, 0.24 * alpha);
    }
  }

  static MeshGeometry _buildStarfieldSectorGeometry(int sector) {
    // Each sector covers a 90° azimuthal quadrant so its AABB lies strictly
    // in one quadrant (at radius ~310 m) and never encloses the camera at (0,0,0).
    const starCount = 60;
    final positions = Float32List(starCount * 4 * 3);
    final colors = Float32List(starCount * 4 * 4);
    final indices = <int>[];

    var seed = 0x51A7F1E1 ^ (sector * 0x27D4EB2D);
    double nextRand() {
      seed = (seed * 1664525 + 1013904223) & 0xFFFFFFFF;
      return (seed & 0x7FFFFFFF) / 0x7FFFFFFF;
    }

    final sectorBaseAz = sector * 90.0;
    for (var i = 0; i < starCount; i++) {
      final azDeg = sectorBaseAz + 4.0 + nextRand() * 82.0;
      final elevDeg = i < 42
          ? (1.5 + nextRand() * 24.0)
          : (25.0 + nextRand() * 42.0);

      final azRad = azDeg * math.pi / 180.0;
      final elRad = elevDeg * math.pi / 180.0;
      final dist = _starDomeRadiusMeters - (nextRand() * 20.0);

      final cx = math.sin(azRad) * math.cos(elRad) * dist;
      final cy = math.sin(elRad) * dist;
      final cz = math.cos(azRad) * math.cos(elRad) * dist;

      // Tangent vectors to build a tiny star diamond facing the origin
      final tx = math.cos(azRad);
      final tz = -math.sin(azRad);
      final size = (i % 7 == 0) ? 1.85 : (0.85 + nextRand() * 0.75);

      final baseVert = i * 4;
      // Top, Right, Bottom, Left vertices of star diamond
      positions[(baseVert + 0) * 3 + 0] = cx;
      positions[(baseVert + 0) * 3 + 1] = cy + size;
      positions[(baseVert + 0) * 3 + 2] = cz;

      positions[(baseVert + 1) * 3 + 0] = cx + tx * size;
      positions[(baseVert + 1) * 3 + 1] = cy;
      positions[(baseVert + 1) * 3 + 2] = cz + tz * size;

      positions[(baseVert + 2) * 3 + 0] = cx;
      positions[(baseVert + 2) * 3 + 1] = cy - size;
      positions[(baseVert + 2) * 3 + 2] = cz;

      positions[(baseVert + 3) * 3 + 0] = cx - tx * size;
      positions[(baseVert + 3) * 3 + 1] = cy;
      positions[(baseVert + 3) * 3 + 2] = cz - tz * size;

      // Star spectral tint (blue-white, pure white, warm gold, amber)
      final spectrum = i % 5;
      final double r;
      final double g;
      final double b;
      if (spectrum == 0) {
        r = 0.78;
        g = 0.88;
        b = 1.0;
      } else if (spectrum == 1) {
        r = 1.0;
        g = 0.94;
        b = 0.76;
      } else if (spectrum == 2) {
        r = 1.0;
        g = 0.82;
        b = 0.64;
      } else {
        r = 0.96;
        g = 0.98;
        b = 1.0;
      }

      final brightness = 0.65 + nextRand() * 0.35;
      for (var v = 0; v < 4; v++) {
        final colIdx = (baseVert + v) * 4;
        colors[colIdx + 0] = r * brightness;
        colors[colIdx + 1] = g * brightness;
        colors[colIdx + 2] = b * brightness;
        colors[colIdx + 3] = 1.0;
      }

      indices
        ..add(baseVert + 0)
        ..add(baseVert + 1)
        ..add(baseVert + 2)
        ..add(baseVert + 0)
        ..add(baseVert + 2)
        ..add(baseVert + 3)
        ..add(baseVert + 0)
        ..add(baseVert + 2)
        ..add(baseVert + 1)
        ..add(baseVert + 0)
        ..add(baseVert + 3)
        ..add(baseVert + 2);
    }

    return MeshGeometry.fromArrays(
      positions: positions,
      colors: colors,
      indices: indices,
    );
  }

  static MeshGeometry _buildProceduralPlanetSphere({
    required double radius,
    required int rings,
    required int segments,
    required _CompanionKind kind,
  }) {
    final vertexCount = (rings + 1) * (segments + 1);
    final positions = Float32List(vertexCount * 3);
    final colors = Float32List(vertexCount * 4);
    final indices = <int>[];

    for (var r = 0; r <= rings; r++) {
      final v = r / rings;
      final phi = v * math.pi;
      final sinPhi = math.sin(phi);
      final cosPhi = math.cos(phi);

      for (var s = 0; s <= segments; s++) {
        final u = s / segments;
        final theta = u * math.pi * 2.0;
        final sinTheta = math.sin(theta);
        final cosTheta = math.cos(theta);

        final nx = sinPhi * cosTheta;
        final ny = cosPhi;
        final nz = sinPhi * sinTheta;

        final idx = r * (segments + 1) + s;
        positions[idx * 3 + 0] = nx * radius;
        positions[idx * 3 + 1] = ny * radius;
        positions[idx * 3 + 2] = nz * radius;

        final col = _evaluatePlanetSurfaceColor(kind, nx, ny, nz);
        // 3D spherical illumination facing the camera (+X, +Z) and sun
        final lightDot =
            (nx * 0.55 + ny * 0.35 + nz * 0.75).clamp(-0.2, 1.0);
        final shade = 0.22 + 0.78 * ((lightDot + 0.2) / 1.2);

        colors[idx * 4 + 0] = (col.r * shade).clamp(0.0, 1.0);
        colors[idx * 4 + 1] = (col.g * shade).clamp(0.0, 1.0);
        colors[idx * 4 + 2] = (col.b * shade).clamp(0.0, 1.0);
        colors[idx * 4 + 3] = 1.0;
      }
    }

    for (var r = 0; r < rings; r++) {
      for (var s = 0; s < segments; s++) {
        final first = r * (segments + 1) + s;
        final second = first + segments + 1;
        indices
          ..add(first)
          ..add(second)
          ..add(first + 1)
          ..add(second)
          ..add(second + 1)
          ..add(first + 1);
      }
    }

    return MeshGeometry.fromArrays(
      positions: positions,
      colors: colors,
      indices: indices,
    );
  }

  static vm.Vector3 _evaluatePlanetSurfaceColor(
    _CompanionKind kind,
    double nx,
    double ny,
    double nz,
  ) {
    switch (kind) {
      case _CompanionKind.moonOnEarth:
        // Lunar highlands + dark basaltic maria + craters
        final mariaPattern = math.sin(nx * 3.1 + ny * 2.4) *
                math.cos(nz * 2.8 - ny * 1.9) +
            0.4 * math.sin(nx * 6.5 - nz * 5.2);
        final craterNoise = math.cos(nx * 14.0 + ny * 12.0 + nz * 14.0) * 0.08;
        final isMare = mariaPattern > 0.12;
        final highland = _parseHexLinearVector3('#DCE4F2');
        final mare = _parseHexLinearVector3('#525B6E');
        final t = ((mariaPattern + 0.3) * 1.2 + craterNoise).clamp(0.0, 1.0);
        final base = isMare
            ? highland + (mare - highland) * t
            : highland * (0.92 + craterNoise);
        return base;

      case _CompanionKind.earthOnMoon:
        // Polar ice caps, continents, deep blue oceans, and swirling white clouds
        final lat = ny.abs();
        if (lat > 0.82) {
          return _parseHexLinearVector3('#F2F8FF');
        }
        final continentVal = math.sin(nx * 2.6 + 0.5) *
                math.cos(ny * 3.2 - 0.3) *
                math.sin(nz * 2.4 + 0.9) +
            0.35 * math.cos(nx * 5.2 - nz * 4.1);
        final cloudVal =
            math.sin(ny * 9.0 + math.sin(nx * 4.0) * 1.5 + nz * 3.5);

        final ocean = _parseHexLinearVector3('#0D478C');
        final landGreen = _parseHexLinearVector3('#287A42');
        final landOchre = _parseHexLinearVector3('#9C7A44');
        final cloudWhite = _parseHexLinearVector3('#F4F9FF');

        var surface = ocean;
        if (continentVal > 0.04) {
          final landMix = ((continentVal - 0.04) * 3.0).clamp(0.0, 1.0);
          surface = landGreen + (landOchre - landGreen) * (lat * 0.9);
          surface = ocean + (surface - ocean) * landMix;
        }
        if (cloudVal > 0.52) {
          final cMix = ((cloudVal - 0.52) * 1.8).clamp(0.0, 0.85);
          surface = surface + (cloudWhite - surface) * cMix;
        }
        return surface;

      case _CompanionKind.jupiterOnTitan:
        // Banded gas giant (equatorial & temperate belts/zones) + Great Red Spot
        final wave = 0.035 * math.sin(nx * 8.0 + nz * 8.0);
        final yBand = ny + wave;
        final bandFreq = math.sin(yBand * 16.5);
        final fineBand = math.cos(yBand * 34.0) * 0.25;

        final zoneCream = _parseHexLinearVector3('#F2DEC2');
        final beltOchre = _parseHexLinearVector3('#D48D44');
        final beltRust = _parseHexLinearVector3('#A84A24');
        final beltDark = _parseHexLinearVector3('#5E2D16');

        var color = bandFreq > 0.2
            ? zoneCream + (beltOchre - zoneCream) * (0.5 - fineBand).clamp(0.0, 1.0)
            : beltRust + (beltDark - beltRust) * (-bandFreq).clamp(0.0, 1.0);

        // Great Red Spot at southern tropical latitude (ny ≈ -0.32) on camera-facing side
        final dLat = (ny + 0.30) / 0.14;
        final dLon = (nx - 0.55) / 0.24;
        final spotDist2 = dLat * dLat + dLon * dLon;
        if (nz > 0.0 && spotDist2 < 1.0) {
          final spotRed = _parseHexLinearVector3('#D9381E');
          final spotMix = (1.0 - spotDist2).clamp(0.0, 1.0);
          color = color + (spotRed - color) * (spotMix * 0.9);
        }
        return color;
    }
  }

  static vm.Vector3 _parseHexLinearVector3(String hex, {double boost = 1.0}) {
    final cleaned = hex.replaceAll('#', '').trim();
    final value = int.tryParse(cleaned, radix: 16) ?? 0x000000;
    final sr = ((value >> 16) & 0xFF) / 255.0;
    final sg = ((value >> 8) & 0xFF) / 255.0;
    final sb = (value & 0xFF) / 255.0;
    final r = math.pow(sr, 2.2).toDouble() * boost;
    final g = math.pow(sg, 2.2).toDouble() * boost;
    final b = math.pow(sb, 2.2).toDouble() * boost;
    return vm.Vector3(r, g, b);
  }

  static vm.Vector4 _parseHexLinearVector4(
    String hex,
    double alpha, {
    double boost = 1.0,
  }) {
    final v3 = _parseHexLinearVector3(hex, boost: boost);
    return vm.Vector4(v3.r, v3.g, v3.b, alpha);
  }
}

enum _CompanionKind {
  moonOnEarth,
  earthOnMoon,
  jupiterOnTitan,
}
