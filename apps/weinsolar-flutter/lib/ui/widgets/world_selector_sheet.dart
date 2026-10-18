import 'package:flutter/material.dart';

import '../../domain/models/celestial_body/celestial_body.dart';

class WorldSelectorSheet extends StatelessWidget {
  static const Color weincodeIndigoDeep = Color(0xFF18084D);
  static const Color weincodeElectricViolet = Color(0xFF5236FF);
  static const Color weincodeSoftLavender = Color(0xFFA599FF);
  static const Color weincodePureWhite = Color(0xFFFFFFFF);

  final List<CelestialBody> worlds;
  final ValueChanged<CelestialBody> onSelectWorld;

  const WorldSelectorSheet({
    super.key,
    required this.worlds,
    required this.onSelectWorld,
  });

  String _formatDecimalEs(double value, {int decimals = 2}) {
    return value.toStringAsFixed(decimals).replaceAll('.', ',');
  }

  String _atmosphereSubtitleEs(CelestialBody world) {
    if (world.atmosphericDensity <= 0.0) {
      return 'Sin atmósfera (vacío 0,0 kg/m³)';
    }
    return 'Atmósfera: ${_formatDecimalEs(world.atmosphericDensity, decimals: 3)} kg/m³';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('world-selector-sheet'),
      color: weincodeIndigoDeep,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'WEINSOLAR v1 — SELECCIÓN DE MUNDO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: weincodePureWhite,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Selecciona un cuerpo celeste para iniciar el descenso vertical 3D y desbloquear la Hora Solar al aterrizar a ≤ 2,0 m/s.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: weincodeSoftLavender,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                ...worlds.map((world) {
                  final gravityFormatted = _formatDecimalEs(
                    world.gravity,
                    decimals: world.id == CelestialBodyId.titan ? 3 : 2,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: weincodeIndigoDeep,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: weincodeElectricViolet,
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        key: Key('world-card-${world.id.name}'),
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onSelectWorld(world),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: weincodeElectricViolet,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: weincodeSoftLavender,
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '×${world.timeScale.toInt()}',
                                  style: const TextStyle(
                                    color: weincodePureWhite,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      world.nameEs,
                                      style: const TextStyle(
                                        color: weincodePureWhite,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Gravedad: $gravityFormatted m/s² • ${_atmosphereSubtitleEs(world)}',
                                      style: const TextStyle(
                                        color: weincodeSoftLavender,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: weincodeElectricViolet,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Iniciar descenso',
                                  style: TextStyle(
                                    color: weincodePureWhite,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
