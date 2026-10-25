import 'package:flutter/material.dart';

import '../../domain/models/celestial_body/celestial_body.dart';
import '../../domain/models/simulation/solar_hour_state.dart';

class SolarHourControlPanel extends StatelessWidget {
  static const Color weincodeIndigoDeep = Color(0xFF18084D);
  static const Color weincodeElectricViolet = Color(0xFF5236FF);
  static const Color weincodeSoftLavender = Color(0xFFA599FF);
  static const Color weincodePureWhite = Color(0xFFFFFFFF);

  final CelestialBody world;
  final SolarHourState solarHourState;
  final ValueChanged<double> onElevationChanged;
  final ValueChanged<double>? onAzimuthChanged;

  const SolarHourControlPanel({
    super.key,
    required this.world,
    required this.solarHourState,
    required this.onElevationChanged,
    this.onAzimuthChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!solarHourState.isUnlocked) {
      return const SizedBox.shrink();
    }

    return Container(
      key: const Key('solar-hour-control-panel'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: weincodeIndigoDeep,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: weincodeElectricViolet,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HORA SOLAR — ${world.nameEs.toUpperCase()}',
                style: const TextStyle(
                  color: weincodePureWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.7,
                ),
              ),
              Text(
                'Sol: ${solarHourState.solarElevationDeg.toStringAsFixed(0)}° • Cámara: ${solarHourState.cameraAzimuthDeg.toStringAsFixed(0)}°',
                style: const TextStyle(
                  color: weincodeSoftLavender,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(
                width: 110,
                child: Text(
                  'Elevación solar',
                  style: TextStyle(
                    color: weincodePureWhite,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: weincodeElectricViolet,
                    inactiveTrackColor: weincodeSoftLavender,
                    thumbColor: weincodePureWhite,
                    overlayColor: weincodeElectricViolet,
                  ),
                  child: Slider(
                    key: const Key('solar-elevation-slider'),
                    min: SolarHourState.minElevationDeg,
                    max: SolarHourState.maxElevationDeg,
                    value: solarHourState.solarElevationDeg.clamp(
                      SolarHourState.minElevationDeg,
                      SolarHourState.maxElevationDeg,
                    ),
                    onChanged: onElevationChanged,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Ref. científica: ${world.scientificReference}',
            style: const TextStyle(
              color: weincodeSoftLavender,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
