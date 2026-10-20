import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../../../domain/models/scene/scene_lighting_state.dart';
import 'scene_descriptor_mapper.dart';

class LanderNodeBundle {
  final Node root;
  final Node? intactNode;
  final Node? destroyedNode;
  final Node? thrusterFlameNode;
  final Node? thrusterLightNode;

  const LanderNodeBundle({
    required this.root,
    required this.intactNode,
    required this.destroyedNode,
    required this.thrusterFlameNode,
    this.thrusterLightNode,
  });
}

class LanderNodeFactory {
  static const String assetPath = 'assets/models/lander.glb';

  static Future<LanderNodeBundle> load() async {
    Node root;
    try {
      root = await Node.fromGlbAsset(assetPath);
    } catch (_) {
      root = await loadScene(assetPath);
    }

    _configureShadowsRecursively(root);

    final intactNode = root.getChildByName('Lander_Intact');
    final destroyedNode = root.getChildByName('Lander_Destroyed');
    final thrusterFlameNode = root.getChildByName('Thruster_Flame');

    final thrusterLightNode = Node(name: 'Thruster_Plume_Light')
      ..position = vm.Vector3(0.0, -0.35, 0.0)
      ..visible = false
      ..addComponent(
        PointLightComponent(
          PointLight(
            color: vm.Vector3(1.0, 0.58, 0.22),
            intensity: 14.0,
            range: 16.0,
          ),
        ),
      );
    root.add(thrusterLightNode);

    return LanderNodeBundle(
      root: root,
      intactNode: intactNode,
      destroyedNode: destroyedNode,
      thrusterFlameNode: thrusterFlameNode,
      thrusterLightNode: thrusterLightNode,
    );
  }

  static void update(
    LanderNodeBundle bundle,
    LanderVisualState lander, {
    SceneLightingState? lighting,
  }) {
    final clampedAltitude = math.max(0.0, lander.altitudeMeters);
    bundle.root.position = vm.Vector3(0.0, clampedAltitude, 0.0);

    final showIntact = lander.visibleNodeName == 'Lander_Intact';
    if (bundle.intactNode != null) {
      bundle.intactNode!.visible = showIntact;
    }
    if (bundle.destroyedNode != null) {
      bundle.destroyedNode!.visible = !showIntact;
    }
    if (bundle.thrusterFlameNode != null) {
      bundle.thrusterFlameNode!.visible = lander.showThrusterFlame;
    }
    if (bundle.thrusterLightNode != null) {
      bundle.thrusterLightNode!.visible = lander.showThrusterFlame;
    }

    if (lighting != null && bundle.intactNode != null) {
      _updateTwilightTint(bundle.intactNode!, lighting);
    }
  }

  static void _configureShadowsRecursively(Node node) {
    if (node.mesh != null) {
      node.shadowCastingMode = node.name == 'Thruster_Flame'
          ? ShadowCastingMode.off
          : ShadowCastingMode.on;
    }
    for (final child in node.children) {
      _configureShadowsRecursively(child);
    }
  }

  static void _updateTwilightTint(
    Node node,
    SceneLightingState lighting,
  ) {
    final lowSunFactor =
        ((18.0 - lighting.solarElevationDeg) / 18.0).clamp(0.0, 1.0);
    final sunColor = _parseHexVector3(lighting.sunColorHex);
    final tintScale = 0.04 + lowSunFactor * 0.10;
    final emissiveVec4 = vm.Vector4(
      sunColor.r * tintScale,
      sunColor.g * tintScale,
      sunColor.b * tintScale,
      1.0,
    );
    final mesh = node.mesh;
    if (mesh != null) {
      for (final primitive in mesh.primitives) {
        final material = primitive.material;
        if (material is PhysicallyBasedMaterial) {
          // Subtle twilight rim glow on hull while preserving authored PBR roughness/metalness
          material.emissiveFactor = emissiveVec4;
        }
      }
    }
    for (final child in node.children) {
      _updateTwilightTint(child, lighting);
    }
  }

  static vm.Vector3 _parseHexVector3(String hex) {
    final cleaned = hex.replaceAll('#', '').trim();
    final value = int.tryParse(cleaned, radix: 16) ?? 0xFFFFFF;
    final r = ((value >> 16) & 0xFF) / 255.0;
    final g = ((value >> 8) & 0xFF) / 255.0;
    final b = (value & 0xFF) / 255.0;
    return vm.Vector3(r, g, b);
  }
}
