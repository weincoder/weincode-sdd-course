import 'package:flutter/material.dart';

import '../../domain/models/scene/visual_quality.dart';

class QualityToggle extends StatelessWidget {
  static const Color weincodeIndigoDeep = Color(0xFF18084D);
  static const Color weincodeElectricViolet = Color(0xFF5236FF);
  static const Color weincodeSoftLavender = Color(0xFFA599FF);
  static const Color weincodePureWhite = Color(0xFFFFFFFF);

  final VisualQuality quality;
  final ValueChanged<VisualQuality> onQualityChanged;

  const QualityToggle({
    super.key,
    required this.quality,
    required this.onQualityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Calidad visual 3D',
      child: SegmentedButton<VisualQuality>(
        key: const Key('quality-toggle'),
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return weincodeElectricViolet;
            }
            return weincodeIndigoDeep;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return weincodePureWhite;
            }
            return weincodeSoftLavender;
          }),
          side: const WidgetStatePropertyAll(
            BorderSide(color: weincodeElectricViolet, width: 1.5),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        segments: const <ButtonSegment<VisualQuality>>[
          ButtonSegment<VisualQuality>(
            value: VisualQuality.high,
            label: Text(
              'Calidad: Alta',
              key: Key('quality-option-high'),
            ),
          ),
          ButtonSegment<VisualQuality>(
            value: VisualQuality.basic,
            label: Text(
              'Calidad: Básica',
              key: Key('quality-option-basic'),
            ),
          ),
        ],
        selected: <VisualQuality>{quality},
        onSelectionChanged: (selection) {
          if (selection.isNotEmpty && selection.first != quality) {
            onQualityChanged(selection.first);
          }
        },
      ),
    );
  }
}
