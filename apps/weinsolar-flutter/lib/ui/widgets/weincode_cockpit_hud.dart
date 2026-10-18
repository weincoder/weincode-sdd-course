import 'package:flutter/material.dart';

import '../../domain/models/celestial_body/celestial_body.dart';
import '../../domain/models/simulation/lander_state.dart';

class WeincodeCockpitHud extends StatelessWidget {
  static const Color weincodeIndigoDeep = Color(0xFF18084D);
  static const Color weincodeElectricViolet = Color(0xFF5236FF);
  static const Color weincodeSoftLavender = Color(0xFFA599FF);
  static const Color weincodePureWhite = Color(0xFFFFFFFF);

  final CelestialBody world;
  final LanderState landerState;
  final VoidCallback onResetInFlight;
  final bool isAutopilotActive;
  final VoidCallback? onToggleAutoLand;

  const WeincodeCockpitHud({
    super.key,
    required this.world,
    required this.landerState,
    required this.onResetInFlight,
    this.isAutopilotActive = false,
    this.onToggleAutoLand,
  });

  String _formatEs(double value, {int decimals = 1}) {
    return value.toStringAsFixed(decimals).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final gravityDecimals = world.id == CelestialBodyId.titan ? 3 : 2;
    final velocitySafe = landerState.isVelocitySafe;
    final velocityStatusText = velocitySafe
        ? 'VELOCIDAD SEGURA (≤ 2,0 m/s)'
        : 'PELIGRO (> 2,0 m/s)';

    return Container(
      key: const Key('weincode-cockpit-hud'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    key: const Key('hud-timescale-badge'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: weincodeElectricViolet,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '×${world.timeScale.toInt()}',
                      style: const TextStyle(
                        color: weincodePureWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${world.nameEs} • g = ${_formatEs(world.gravity, decimals: gravityDecimals)} m/s²',
                    key: const Key('hud-world-gravity'),
                    style: const TextStyle(
                      color: weincodePureWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Text(
                    'Umbral: ≤ 2,0 m/s • Techo: ${world.ceilingAltitude.toInt()} m',
                    style: const TextStyle(
                      color: weincodeSoftLavender,
                      fontSize: 11,
                    ),
                  ),
                  if (landerState.status == LanderStatus.descending &&
                      onToggleAutoLand != null)
                    OutlinedButton(
                      key: const Key('auto-land-button'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: weincodePureWhite,
                        backgroundColor: isAutopilotActive
                            ? weincodeElectricViolet
                            : weincodeIndigoDeep,
                        side: BorderSide(
                          color: isAutopilotActive
                              ? weincodePureWhite
                              : weincodeElectricViolet,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        minimumSize: const Size(0, 30),
                      ),
                      onPressed: onToggleAutoLand,
                      child: Text(
                        isAutopilotActive
                            ? 'Piloto automático: ACTIVO'
                            : 'Aterrizaje automático',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  OutlinedButton(
                    key: const Key('in-flight-reset-button'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: weincodePureWhite,
                      backgroundColor: weincodeIndigoDeep,
                      side: const BorderSide(
                        color: weincodeElectricViolet,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: const Size(0, 30),
                    ),
                    onPressed: onResetInFlight,
                    child: const Text(
                      'Reiniciar',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _TelemetryMetricChip(
                metricKey: const Key('hud-altitude-value'),
                label: 'ALTITUD',
                value: '${_formatEs(landerState.altitude)} m',
                sublabel: landerState.isNearCeiling
                    ? 'ALERTA PROXIMIDAD TECHO'
                    : 'Superficie a 0,0 m',
                isHighlighted: landerState.isNearCeiling,
              ),
              _TelemetryMetricChip(
                metricKey: const Key('hud-velocity-value'),
                label: 'VELOCIDAD VERTICAL',
                value: '${_formatEs(landerState.verticalVelocity)} m/s',
                sublabel: velocityStatusText,
                isHighlighted: !velocitySafe,
              ),
              _TelemetryMetricChip(
                metricKey: const Key('hud-fuel-value'),
                label: 'COMBUSTIBLE',
                value: '${_formatEs(landerState.fuelPercentage)}%',
                sublabel: landerState.isOutOfFuel
                    ? 'Sin combustible'
                    : 'Reserva activa',
                isHighlighted: landerState.isOutOfFuel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TelemetryMetricChip extends StatelessWidget {
  final Key metricKey;
  final String label;
  final String value;
  final String sublabel;
  final bool isHighlighted;

  const _TelemetryMetricChip({
    required this.metricKey,
    required this.label,
    required this.value,
    required this.sublabel,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlighted
            ? WeincodeCockpitHud.weincodeElectricViolet
            : WeincodeCockpitHud.weincodeIndigoDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlighted
              ? WeincodeCockpitHud.weincodePureWhite
              : WeincodeCockpitHud.weincodeSoftLavender,
          width: isHighlighted ? 2.0 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: WeincodeCockpitHud.weincodeSoftLavender,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            key: metricKey,
            style: const TextStyle(
              color: WeincodeCockpitHud.weincodePureWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: const TextStyle(
              color: WeincodeCockpitHud.weincodePureWhite,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
