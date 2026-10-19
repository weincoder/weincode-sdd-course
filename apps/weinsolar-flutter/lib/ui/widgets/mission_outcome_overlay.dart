import 'package:flutter/material.dart';

import '../../domain/models/celestial_body/celestial_body.dart';
import '../../domain/models/simulation/mission_attempt.dart';

class MissionOutcomeOverlay extends StatelessWidget {
  static const Color weincodeIndigoDeep = Color(0xFF18084D);
  static const Color weincodeElectricViolet = Color(0xFF5236FF);
  static const Color weincodeSoftLavender = Color(0xFFA599FF);
  static const Color weincodePureWhite = Color(0xFFFFFFFF);

  final CelestialBody world;
  final MissionAttempt attempt;
  final VoidCallback onRetry;
  final VoidCallback onChangeWorld;

  const MissionOutcomeOverlay({
    super.key,
    required this.world,
    required this.attempt,
    required this.onRetry,
    required this.onChangeWorld,
  });

  String _formatEs(double value, {int decimals = 1}) {
    return value.toStringAsFixed(decimals).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    if (attempt.outcome == MissionOutcome.inProgress ||
        attempt.outcome == MissionOutcome.abandoned) {
      return const SizedBox.shrink();
    }

    final isSuccess = attempt.outcome == MissionOutcome.success;
    final isSignalLost = attempt.outcome == MissionOutcome.failedSignalLost;

    final title = isSuccess
        ? 'Aterrizaje exitoso'
        : (isSignalLost ? 'Misión fallida – señal perdida' : 'Misión fallida');

    final touchdownSpeed = (attempt.touchdownVelocity ?? 0.0).abs();

    return Container(
      key: const Key('mission-outcome-overlay'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: weincodeIndigoDeep,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSuccess ? weincodeElectricViolet : weincodeSoftLavender,
          width: 2.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                color: weincodePureWhite,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  key: const Key('mission-outcome-title'),
                  style: const TextStyle(
                    color: weincodePureWhite,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: weincodeElectricViolet,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  world.nameEs,
                  style: const TextStyle(
                    color: weincodePureWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isSuccess) ...[
            Text(
              'Velocidad de contacto: ${_formatEs(touchdownSpeed)} m/s (umbral ≤ 2,0 m/s) • Combustible restante: ${_formatEs(attempt.remainingFuel)}%',
              style: const TextStyle(
                color: weincodePureWhite,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Hora Solar desbloqueada: desplaza el sol hacia el horizonte y gira la cámara 360°.',
              style: TextStyle(
                color: weincodeSoftLavender,
                fontSize: 12,
              ),
            ),
          ] else ...[
            Text(
              attempt.failureReasonEs ?? 'Misión fallida',
              style: const TextStyle(
                color: weincodePureWhite,
                fontSize: 13,
              ),
            ),
            if (attempt.touchdownVelocity != null) ...[
              const SizedBox(height: 2),
              Text(
                'Velocidad de impacto registrada: ${_formatEs(touchdownSpeed)} m/s • Sonda destruida',
                style: const TextStyle(
                  color: weincodeSoftLavender,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 4),
            const Text(
              'Hora Solar bloqueada: logra un aterrizaje suave (≤ 2,0 m/s) para observar el ocaso.',
              style: TextStyle(
                color: weincodeSoftLavender,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                key: const Key('change-world-button'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: weincodePureWhite,
                  side: const BorderSide(color: weincodeSoftLavender, width: 1.5),
                  backgroundColor: weincodeIndigoDeep,
                ),
                onPressed: onChangeWorld,
                child: const Text('Cambiar mundo'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                key: const Key('retry-mission-button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: weincodeElectricViolet,
                  foregroundColor: weincodePureWhite,
                ),
                onPressed: onRetry,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
