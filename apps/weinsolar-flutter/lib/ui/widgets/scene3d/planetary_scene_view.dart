import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../../../domain/models/celestial_body/celestial_body.dart';
import '../../../domain/models/scene/camera_mode.dart';
import 'lander_node_factory.dart';
import 'scene_descriptor_mapper.dart';
import 'sun_light_binding.dart';
import 'terrain_geometry_builder.dart';

class PlanetarySceneView extends StatefulWidget {
  final SceneDescriptor descriptor;
  final ValueChanged<double>? onOrbitAzimuthDelta;
  final VoidCallback? onSceneReady;

  const PlanetarySceneView({
    super.key,
    required this.descriptor,
    this.onOrbitAzimuthDelta,
    this.onSceneReady,
  });

  @override
  State<PlanetarySceneView> createState() => _PlanetarySceneViewState();
}

class _PlanetarySceneViewState extends State<PlanetarySceneView> {
  Scene? _scene;
  Node? _sunLightNode;
  Node? _terrainNode;
  LanderNodeBundle? _landerBundle;
  CelestialBodyId? _builtWorldId;
  int? _builtTerrainResolution;
  bool _gpuAvailable = true;
  bool _notifiedReady = false;

  double _smoothedLookAtY = 100.0;
  double _orbitPolarDeg = 12.0;
  final double _orbitRadiusMeters = 14.5;

  @override
  void initState() {
    super.initState();
    _smoothedLookAtY = math.max(0.0, widget.descriptor.lander.altitudeMeters);
    _initializeSceneGraph();
  }

  Future<void> _initializeSceneGraph() async {
    try {
      try {
        await Scene.preload(physicalMaterials: true);
      } catch (_) {
        await Scene.initializeStaticResources();
      }
      final scene = Scene();
      final sunLightNode = Node(name: 'Sun_Light_Node');
      scene.add(sunLightNode);

      final terrainNode = TerrainGeometryBuilder.build(
        layout: widget.descriptor.terrain,
        theme: widget.descriptor.terrainTheme,
      );
      scene.add(terrainNode);

      LanderNodeBundle? landerBundle;
      try {
        landerBundle = await LanderNodeFactory.load();
        scene.add(landerBundle.root);
      } catch (_) {
        // Fallback if asset bundle cannot load in test environment
      }

      if (!mounted) {
        scene.removeAll();
        return;
      }

      _scene = scene;
      _sunLightNode = sunLightNode;
      _terrainNode = terrainNode;
      _landerBundle = landerBundle;
      _builtWorldId = widget.descriptor.worldId;
      _builtTerrainResolution = widget.descriptor.quality.terrainResolution;

      _syncSceneNodes();

      // Pre-compile GPU render pipelines offscreen before revealing the scene
      // so the first visible frame does not stall ~237ms mid-frame.
      try {
        await scene.warmUp(
          [RenderView(camera: _buildCamera())],
          includeOffscreen: true,
        );
      } catch (_) {
        // Ignore warmUp errors in headless unit test environments
      }

      if (!mounted) {
        scene.removeAll();
        return;
      }

      _notifyReadyOnce();
      setState(() {});
    } catch (_) {
      if (!mounted) {
        return;
      }
      _gpuAvailable = false;
      _notifyReadyOnce();
      setState(() {});
    }
  }

  void _notifyReadyOnce() {
    if (!_notifiedReady) {
      _notifiedReady = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onSceneReady?.call();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant PlanetarySceneView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_scene != null) {
      _syncSceneNodes();
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    _builtWorldId = null;
    if (_scene != null) {
      _syncSceneNodes();
    }
  }

  void _syncSceneNodes() {
    final scene = _scene;
    final sunLightNode = _sunLightNode;
    if (scene == null || sunLightNode == null) {
      return;
    }

    final d = widget.descriptor;

    // Hot-rebuild terrain only when worldId or quality terrainResolution changes (T067)
    if (_builtWorldId != d.worldId ||
        _builtTerrainResolution != d.quality.terrainResolution) {
      if (_terrainNode != null) {
        scene.remove(_terrainNode!);
      }
      _terrainNode = TerrainGeometryBuilder.build(
        layout: d.terrain,
        theme: d.terrainTheme,
      );
      scene.add(_terrainNode!);
      _builtWorldId = d.worldId;
      _builtTerrainResolution = d.quality.terrainResolution;
    }

    if (_landerBundle != null) {
      LanderNodeFactory.update(
        _landerBundle!,
        d.lander,
        lighting: d.lighting,
      );
    }

    SunLightBinding.apply(
      scene: scene,
      sunLightNode: sunLightNode,
      lighting: d.lighting,
      skyProfile: d.skyOpticalProfile,
      quality: d.quality,
      landerAltitude: d.lander.altitudeMeters,
      worldId: d.worldId,
    );
  }

  Camera _buildCamera() {
    final d = widget.descriptor;
    final sunDir = d.lighting.sunDirection;
    final sunAzDeg =
        (math.atan2(sunDir.x, sunDir.z) * 180.0 / math.pi + 360.0) % 360.0;

    if (d.cameraMode == CameraMode.orbit) {
      final effectiveAzDeg = d.cameraAzimuthDeg == 0.0
          ? (sunAzDeg + 180.0) % 360.0
          : d.cameraAzimuthDeg;

      final azimuthRad = effectiveAzDeg * math.pi / 180.0;
      final polarRad = _orbitPolarDeg.clamp(4.0, 85.0) * math.pi / 180.0;
      final radius = _orbitRadiusMeters.clamp(6.0, 60.0);
      final target = vm.Vector3(0.0, 2.2, 0.0);

      final camX = radius * math.cos(polarRad) * math.sin(azimuthRad);
      final camY = target.y + radius * math.sin(polarRad);
      final camZ = radius * math.cos(polarRad) * math.cos(azimuthRad);

      return PerspectiveCamera(
        position: vm.Vector3(camX, math.max(0.8, camY), camZ),
        target: target,
        fovRadiansY: 54.0 * math.pi / 180.0,
        fovNear: 0.5,
        fovFar: 1200.0,
      );
    }

    final targetY = math.max(0.0, d.lander.altitudeMeters);
    // If the mission was reset or world changed (large altitude jump), snap immediately.
    // Otherwise track the probe closely with responsive smoothing so the camera
    // never lags far above the descending lander.
    if ((targetY - _smoothedLookAtY).abs() > 25.0) {
      _smoothedLookAtY = targetY;
    } else {
      _smoothedLookAtY += (targetY - _smoothedLookAtY) * 0.55;
    }

    final dist = math.min(18.5, math.max(13.5, 13.5 + _smoothedLookAtY * 0.012));

    // Position the lateral-follow camera opposite the Sun's horizontal azimuth (+14° offset)
    // and at nearly eye-level with the spacecraft cabin (+0.35 m above target) so the camera
    // follows directly alongside the probe instead of looking down from high above.
    final followAzRad = ((sunAzDeg + 194.0) % 360.0) * math.pi / 180.0;
    final camX = dist * math.sin(followAzRad);
    final camZ = dist * math.cos(followAzRad);
    final lookAtY = _smoothedLookAtY + 1.75;

    return PerspectiveCamera(
      position: vm.Vector3(camX, lookAtY + 0.35, camZ),
      target: vm.Vector3(0.0, lookAtY, 0.0),
      fovRadiansY: 50.0 * math.pi / 180.0,
      fovNear: 0.5,
      fovFar: 1200.0,
    );
  }

  @override
  void dispose() {
    _scene?.removeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOrbit = widget.descriptor.cameraMode == CameraMode.orbit;

    return GestureDetector(
      key: const Key('planetary-scene-view'),
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: isOrbit
          ? (details) {
              widget.onOrbitAzimuthDelta?.call(details.delta.dx * 0.45);
            }
          : null,
      onVerticalDragUpdate: isOrbit
          ? (details) {
              setState(() {
                _orbitPolarDeg =
                    (_orbitPolarDeg - details.delta.dy * 0.25).clamp(4.0, 85.0);
              });
            }
          : null,
      child: _buildViewportContent(context),
    );
  }

  Widget _buildViewportContent(BuildContext context) {
    if (!_gpuAvailable || _scene == null) {
      return Container(
        key: const Key('planetary-scene-fallback'),
        color: const Color(0xFF0A0D18),
      );
    }

    final camera = _buildCamera();
    final deviceDpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    final effectiveDpr = math.min(
      math.min(deviceDpr, 1.5),
      widget.descriptor.quality.maxPixelRatio,
    );

    return CustomPaint(
      key: const Key('planetary-scene-gpu-canvas'),
      painter: _SceneViewPainter(
        scene: _scene!,
        camera: camera,
        pixelRatio: effectiveDpr,
      ),
      size: Size.infinite,
    );
  }
}

class _SceneViewPainter extends CustomPainter {
  final Scene scene;
  final Camera camera;
  final double pixelRatio;

  _SceneViewPainter({
    required this.scene,
    required this.camera,
    required this.pixelRatio,
  }) : super(repaint: scene.repaintRequested);

  @override
  void paint(Canvas canvas, Size size) {
    scene.render(
      camera,
      canvas,
      viewport: Offset.zero & size,
      pixelRatio: pixelRatio,
    );
  }

  @override
  bool shouldRepaint(covariant _SceneViewPainter oldDelegate) => true;
}
