import 'package:flutter/material.dart';

class ThrusterControlButton extends StatelessWidget {
  static const Color weincodeIndigoDeep = Color(0xFF18084D);
  static const Color weincodeElectricViolet = Color(0xFF5236FF);
  static const Color weincodeSoftLavender = Color(0xFFA599FF);
  static const Color weincodePureWhite = Color(0xFFFFFFFF);

  final bool isThrusterActive;
  final bool isOutOfFuel;
  final bool isEnabled;
  final ValueChanged<bool> onThrusterChanged;

  const ThrusterControlButton({
    super.key,
    required this.isThrusterActive,
    required this.isOutOfFuel,
    required this.isEnabled,
    required this.onThrusterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final canFire = isEnabled && !isOutOfFuel;
    final activeVisual = canFire && isThrusterActive;

    final label = isOutOfFuel
        ? 'SIN COMBUSTIBLE (0%)'
        : (activeVisual ? 'PROPULSOR ACTIVO' : 'MANTENER PROPULSOR');

    return Listener(
      onPointerDown: canFire ? (_) => onThrusterChanged(true) : null,
      onPointerUp: canFire ? (_) => onThrusterChanged(false) : null,
      onPointerCancel: canFire ? (_) => onThrusterChanged(false) : null,
      child: GestureDetector(
        key: const Key('thruster-control-button'),
        behavior: HitTestBehavior.opaque,
        onTapDown: canFire ? (_) => onThrusterChanged(true) : null,
        onTapUp: canFire ? (_) => onThrusterChanged(false) : null,
        onTapCancel: canFire ? () => onThrusterChanged(false) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: activeVisual ? weincodeElectricViolet : weincodeIndigoDeep,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: canFire ? weincodeElectricViolet : weincodeSoftLavender,
              width: activeVisual ? 3.0 : 2.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOutOfFuel
                    ? Icons.warning_amber_rounded
                    : Icons.rocket_launch_rounded,
                color: canFire ? weincodePureWhite : weincodeSoftLavender,
                size: 22,
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: canFire ? weincodePureWhite : weincodeSoftLavender,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Text(
                    'Espacio / Flecha Arriba o mantener pulsado',
                    style: TextStyle(
                      color: weincodeSoftLavender,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
