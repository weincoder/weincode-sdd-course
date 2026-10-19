import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/celestial_body/celestial_body.dart';
import '../../domain/models/simulation/lander_state.dart';
import '../../domain/models/simulation/solar_hour_state.dart';

class PlanetaryScene3dPainter extends CustomPainter {
  final CelestialBody world;
  final LanderState landerState;
  final SolarHourState solarHourState;

  const PlanetaryScene3dPainter({
    required this.world,
    required this.landerState,
    required this.solarHourState,
  });

  static Color parseHexColor(String hex) {
    final clean = hex.replaceFirst('#', '').trim();
    final rgb = int.parse(clean, radix: 16);
    return Color(0xFF000000 | rgb);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final isSolarMode = solarHourState.isUnlocked;
    final sunElevationDeg = isSolarMode
        ? solarHourState.solarElevationDeg
        : SolarHourState.defaultInitialElevationDeg;
    final azimuthDeg = isSolarMode ? solarHourState.cameraAzimuthDeg : 0.0;
    final azimuthRad = azimuthDeg * math.pi / 180.0;

    final zenithColor = parseHexColor(
      isSolarMode
          ? solarHourState.zenithColorHex
          : world.skyOpticalProfile.dayZenithHex,
    );
    final horizonColor = parseHexColor(
      isSolarMode
          ? solarHourState.horizonColorHex
          : world.skyOpticalProfile.dayHorizonHex,
    );
    final haloColor = parseHexColor(
      isSolarMode
          ? solarHourState.sunHaloColorHex
          : world.skyOpticalProfile.sunHaloHex,
    );

    final directLight = isSolarMode
        ? solarHourState.directLightIntensity
        : 1.0;
    final ambientLight = isSolarMode
        ? solarHourState.ambientLightIntensity
        : (world.id == CelestialBodyId.moon ? 0.0 : 0.55);
    final shadowHardness = isSolarMode
        ? solarHourState.shadowHardness
        : (world.id == CelestialBodyId.moon
            ? 1.0
            : (world.id == CelestialBodyId.titan ? 0.15 : 0.6));

    // Horizon line shifts higher during descent to show surface below, and centers in Solar Hour mode
    final horizonY = isSolarMode ? size.height * 0.54 : size.height * 0.62;

    // 1. Paint Sky (FR-015, FR-030)
    final skyRect = Rect.fromLTWH(0, 0, size.width, horizonY);
    if (world.id == CelestialBodyId.moon) {
      canvas.drawRect(skyRect, Paint()..color = const Color(0xFF000000));
      _paintLunarStars(canvas, size, horizonY, azimuthRad);
    } else {
      final skyPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [zenithColor, horizonColor],
        ).createShader(skyRect);
      canvas.drawRect(skyRect, skyPaint);
    }

    // 2. Paint Sun & Circumsolar Halo (FR-015, FR-029)
    _paintSunAndHalo(
      canvas: canvas,
      size: size,
      horizonY: horizonY,
      sunElevationDeg: sunElevationDeg,
      azimuthDeg: azimuthDeg,
      haloColor: haloColor,
    );

    // 3. Paint Ground Base & 3D Perspective Grid/Terrain (FR-027, FR-028, FR-030)
    final totalLight = (directLight * 0.75 + ambientLight * 0.55).clamp(
      world.id == CelestialBodyId.moon && sunElevationDeg < 0.0 ? 0.04 : 0.08,
      1.0,
    );

    final baseSurfaceColor = _applyLight(
      parseHexColor(world.terrainTheme.primarySurfaceHex),
      totalLight,
    );
    final featureColor = _applyLight(
      parseHexColor(world.terrainTheme.secondaryFeatureHex),
      totalLight,
    );
    final padColor = _applyLight(
      parseHexColor(world.terrainTheme.landingPadHex),
      totalLight,
    );

    final groundRect = Rect.fromLTWH(
      0,
      horizonY,
      size.width,
      size.height - horizonY,
    );
    canvas.drawRect(groundRect, Paint()..color = baseSurfaceColor);

    // 3D Camera setup
    // Visual altitude compressed so both lander and ground stay visible during descent (FR-027)
    final normalizedAlt =
        (landerState.altitude / world.initialAltitude).clamp(0.0, 1.5);
    final landerWorldY = normalizedAlt * 18.0;

    final camDist = isSolarMode ? 14.0 : (20.0 + normalizedAlt * 8.0);
    final camHeight = isSolarMode ? 3.2 : (6.0 + landerWorldY * 0.65);
    final lookAtY = isSolarMode ? 1.8 : (landerWorldY * 0.45);

    Offset? project3D(double wx, double wy, double wz) {
      // Rotate world around Y axis by camera azimuth
      final cosA = math.cos(azimuthRad);
      final sinA = math.sin(azimuthRad);
      final rx = wx * cosA - wz * sinA;
      final rz = wx * sinA + wz * cosA;

      // Translate relative to camera at (0, camHeight, -camDist)
      final cy = wy - camHeight;
      final cz = rz + camDist;

      // Camera pitch looking toward (0, lookAtY, 0)
      final pitch = math.atan2(lookAtY - camHeight, camDist);
      final cosP = math.cos(pitch);
      final sinP = math.sin(pitch);

      final vy = cy * cosP - cz * sinP;
      final vz = cy * sinP + cz * cosP;

      if (vz <= 1.0) {
        return null;
      }

      final fovScale = size.shortestSide * 0.95;
      final sx = size.width * 0.5 + (rx / vz) * fovScale;
      final sy = horizonY - (vy / vz) * fovScale;
      return Offset(sx, sy);
    }

    // Draw 3D perspective terrain grid lines
    final gridPaint = Paint()
      ..color = featureColor.withValues(alpha: 0.45)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (var i = -24; i <= 24; i += 6) {
      final p1 = project3D(i.toDouble(), 0, -24);
      final p2 = project3D(i.toDouble(), 0, 24);
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, gridPaint);
      }
      final q1 = project3D(-24, 0, i.toDouble());
      final q2 = project3D(24, 0, i.toDouble());
      if (q1 != null && q2 != null) {
        canvas.drawLine(q1, q2, gridPaint);
      }
    }

    // Draw world-specific perimeter 3D terrain features outside the flat landing pad (FR-028)
    _paintPerimeterTerrainFeatures(
      canvas: canvas,
      project3D: project3D,
      featureColor: featureColor,
      sunElevationDeg: sunElevationDeg,
      azimuthRad: azimuthRad,
      shadowHardness: shadowHardness,
      directLight: directLight,
    );

    // Draw flat circular 3D landing pad at (0, 0, 0)
    final padPath = Path();
    const padRadius = 4.2;
    var firstPadPoint = true;
    for (var deg = 0; deg <= 360; deg += 15) {
      final rad = deg * math.pi / 180.0;
      final pt = project3D(
        math.cos(rad) * padRadius,
        0.0,
        math.sin(rad) * padRadius,
      );
      if (pt != null) {
        if (firstPadPoint) {
          padPath.moveTo(pt.dx, pt.dy);
          firstPadPoint = false;
        } else {
          padPath.lineTo(pt.dx, pt.dy);
        }
      }
    }
    padPath.close();
    canvas.drawPath(padPath, Paint()..color = padColor);
    canvas.drawPath(
      padPath,
      Paint()
        ..color = featureColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // 4. Paint Dynamic Lander Shadow on Landing Pad (FR-030)
    if (directLight > 0.02 && sunElevationDeg >= 0.0) {
      final elevRad = (sunElevationDeg.clamp(3.0, 88.0)) * math.pi / 180.0;
      final shadowOffsetMag =
          (1.8 / math.tan(elevRad)).clamp(0.2, 8.0) + landerWorldY * 0.15;
      final shadowCenter = project3D(shadowOffsetMag, 0.0, 0.0);
      if (shadowCenter != null) {
        final shadowScale = (1.0 / (1.0 + landerWorldY * 0.08)).clamp(0.3, 1.0);
        final shadowAlpha =
            (0.25 + 0.65 * shadowHardness * directLight).clamp(0.1, 0.9);
        final shadowPaint = Paint()
          ..color = const Color(0xFF050505).withValues(alpha: shadowAlpha);
        if (shadowHardness < 0.4) {
          shadowPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
        }
        canvas.drawOval(
          Rect.fromCenter(
            center: shadowCenter,
            width: 46.0 * shadowScale,
            height: 18.0 * shadowScale,
          ),
          shadowPaint,
        );
      }
    }

    // 5. Paint 3D Lander Mesh (Intact or Crashed)
    _paintLander3D(
      canvas: canvas,
      project3D: project3D,
      landerWorldY: landerWorldY,
      totalLight: totalLight,
    );

    // Optional atmospheric haze overlay for Titan (FR-015, FR-028)
    if (world.id == CelestialBodyId.titan) {
      final hazePaint = Paint()
        ..color = horizonColor.withValues(alpha: 0.18);
      canvas.drawRect(Offset.zero & size, hazePaint);
    }
  }

  void _paintLunarStars(
    Canvas canvas,
    Size size,
    double horizonY,
    double azimuthRad,
  ) {
    final starPaint = Paint()..color = const Color(0xFFDDE2E6);
    for (var i = 0; i < 36; i++) {
      final seedX = ((i * 73 + (azimuthRad * 40).round()) % 100) / 100.0;
      final seedY = ((i * 41) % 85) / 100.0;
      canvas.drawCircle(
        Offset(seedX * size.width, seedY * horizonY),
        (i % 3 == 0) ? 1.5 : 1.0,
        starPaint,
      );
    }
  }

  void _paintSunAndHalo({
    required Canvas canvas,
    required Size size,
    required double horizonY,
    required double sunElevationDeg,
    required double azimuthDeg,
    required Color haloColor,
  }) {
    if (world.id == CelestialBodyId.moon && sunElevationDeg < 0.0) {
      // Abrupt cutoff below horizon on the Moon (FR-015, CA-US2-4)
      return;
    }

    final normalizedElev = (sunElevationDeg / 90.0).clamp(-0.15, 1.0);
    final sunY = horizonY - normalizedElev * (horizonY * 0.78);
    final azimuthOffset = math.sin(azimuthDeg * math.pi / 180.0) * (size.width * 0.28);
    final sunCenter = Offset(size.width * 0.5 + azimuthOffset, sunY);

    if (world.id != CelestialBodyId.moon) {
      final haloRadius = world.id == CelestialBodyId.titan ? 90.0 : 68.0;
      final haloPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            haloColor.withValues(alpha: 0.75),
            haloColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: sunCenter, radius: haloRadius));
      canvas.drawCircle(sunCenter, haloRadius, haloPaint);
    }

    if (sunElevationDeg >= -3.0) {
      final discRadius = world.id == CelestialBodyId.titan ? 10.0 : 14.0;
      final discColor = world.id == CelestialBodyId.titan
          ? const Color(0xFFFFB76B).withValues(alpha: 0.65)
          : const Color(0xFFFFFAED);
      canvas.drawCircle(sunCenter, discRadius, Paint()..color = discColor);
    }
  }

  void _paintPerimeterTerrainFeatures({
    required Canvas canvas,
    required Offset? Function(double wx, double wy, double wz) project3D,
    required Color featureColor,
    required double sunElevationDeg,
    required double azimuthRad,
    required double shadowHardness,
    required double directLight,
  }) {
    const featurePositions = <(double x, double z, double h, double r)>[
      (-10.0, 8.0, 2.2, 1.8),
      (11.0, 9.0, 2.8, 2.1),
      (-14.0, -6.0, 1.9, 1.6),
      (13.0, -8.0, 2.4, 1.9),
      (-7.0, 15.0, 3.2, 2.5),
      (8.0, 16.0, 3.0, 2.3),
    ];

    for (final pos in featurePositions) {
      final baseLeft = project3D(pos.$1 - pos.$4, 0.0, pos.$2);
      final baseRight = project3D(pos.$1 + pos.$4, 0.0, pos.$2);
      final peak = project3D(
        pos.$1,
        world.id == CelestialBodyId.moon ? 0.5 : pos.$3,
        pos.$2,
      );

      if (baseLeft != null && baseRight != null && peak != null) {
        if (world.id == CelestialBodyId.moon) {
          // Draw 3D crater rim on the Moon
          final center = project3D(pos.$1, 0.0, pos.$2);
          if (center != null) {
            final rimWidth = (baseRight.dx - baseLeft.dx).abs().clamp(10.0, 80.0);
            canvas.drawOval(
              Rect.fromCenter(
                center: center,
                width: rimWidth,
                height: rimWidth * 0.38,
              ),
              Paint()..color = featureColor,
            );
          }
        } else {
          // Draw 3D rock / mound / icy ridge
          final path = Path()
            ..moveTo(baseLeft.dx, baseLeft.dy)
            ..lineTo(peak.dx, peak.dy)
            ..lineTo(baseRight.dx, baseRight.dy)
            ..close();
          canvas.drawPath(path, Paint()..color = featureColor);
        }
      }
    }
  }

  void _paintLander3D({
    required Canvas canvas,
    required Offset? Function(double wx, double wy, double wz) project3D,
    required double landerWorldY,
    required double totalLight,
  }) {
    final centerBottom = project3D(0.0, landerWorldY, 0.0);
    final centerTop = project3D(0.0, landerWorldY + 2.2, 0.0);
    if (centerBottom == null || centerTop == null) {
      return;
    }

    final bodyColor = _applyLight(const Color(0xFFD6DCE2), totalLight);
    final accentGold = _applyLight(const Color(0xFFD49B35), totalLight);
    final strutColor = _applyLight(const Color(0xFF4A525A), totalLight);

    if (landerState.status == LanderStatus.crashed) {
      // Crashed debris representation (FR-011)
      final debrisPaint = Paint()..color = strutColor;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(centerBottom.dx - 12, centerBottom.dy - 4),
          width: 16,
          height: 8,
        ),
        debrisPaint,
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(centerBottom.dx + 10, centerBottom.dy - 3),
          width: 14,
          height: 7,
        ),
        Paint()..color = accentGold,
      );
      return;
    }

    // Active thruster plume when firing with fuel (FR-006, FR-007)
    if (landerState.isThrusterActive && !landerState.isOutOfFuel) {
      final plumeTip = project3D(0.0, math.max(0.0, landerWorldY - 1.8), 0.0);
      if (plumeTip != null) {
        final plumePath = Path()
          ..moveTo(centerBottom.dx - 7, centerBottom.dy)
          ..lineTo(plumeTip.dx, plumeTip.dy)
          ..lineTo(centerBottom.dx + 7, centerBottom.dy)
          ..close();
        canvas.drawPath(plumePath, Paint()..color = const Color(0xFFFF9E3D));
      }
    }

    // 4 3D landing legs
    final legPaint = Paint()
      ..color = strutColor
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    for (final legOffset in const [
      (-1.5, -1.5),
      (1.5, -1.5),
      (-1.5, 1.5),
      (1.5, 1.5),
    ]) {
      final foot = project3D(legOffset.$1, landerWorldY, legOffset.$2);
      final hip = project3D(
        legOffset.$1 * 0.55,
        landerWorldY + 0.9,
        legOffset.$2 * 0.55,
      );
      if (foot != null && hip != null) {
        canvas.drawLine(hip, foot, legPaint);
      }
    }

    // Descent stage foil base
    final baseHeight = (centerBottom.dy - centerTop.dy).abs().clamp(16.0, 64.0);
    final baseWidth = baseHeight * 1.05;
    final moduleCenter = Offset(
      centerBottom.dx,
      centerBottom.dy - baseHeight * 0.55,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: moduleCenter,
          width: baseWidth,
          height: baseHeight * 0.48,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = accentGold,
    );

    // Upper crew/instrument capsule
    final capsulePath = Path()
      ..moveTo(moduleCenter.dx - baseWidth * 0.42, moduleCenter.dy - baseHeight * 0.18)
      ..lineTo(moduleCenter.dx - baseWidth * 0.24, centerTop.dy)
      ..lineTo(moduleCenter.dx + baseWidth * 0.24, centerTop.dy)
      ..lineTo(moduleCenter.dx + baseWidth * 0.42, moduleCenter.dy - baseHeight * 0.18)
      ..close();
    canvas.drawPath(capsulePath, Paint()..color = bodyColor);
  }

  Color _applyLight(Color base, double factor) {
    final f = factor.clamp(0.05, 1.0);
    final r = ((base.r * 255.0) * f).round().clamp(0, 255);
    final g = ((base.g * 255.0) * f).round().clamp(0, 255);
    final b = ((base.b * 255.0) * f).round().clamp(0, 255);
    return Color.fromARGB(255, r, g, b);
  }

  @override
  bool shouldRepaint(covariant PlanetaryScene3dPainter oldDelegate) {
    return oldDelegate.world != world ||
        oldDelegate.landerState != landerState ||
        oldDelegate.solarHourState != solarHourState;
  }
}
