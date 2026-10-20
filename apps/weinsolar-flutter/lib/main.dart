import 'package:flutter/material.dart';

import 'config/providers/simulation_provider.dart';
import 'config/routes/app_routes.dart';
import 'domain/usecase/compute_scene_lighting_use_case.dart';
import 'domain/usecase/evaluate_solar_hour_use_case.dart';
import 'domain/usecase/generate_terrain_layout_use_case.dart';
import 'domain/usecase/get_celestial_bodies_use_case.dart';
import 'domain/usecase/resolve_camera_mode_use_case.dart';
import 'domain/usecase/simulate_descent_step_use_case.dart';
import 'infrastructure/driven_adapters/celestial_body_local_adapter.dart';

void main() {
  const gateway = CelestialBodyLocalAdapter();
  const getCelestialBodiesUseCase = GetCelestialBodiesUseCase(gateway: gateway);
  const simulateDescentStepUseCase = SimulateDescentStepUseCase();
  const evaluateSolarHourUseCase = EvaluateSolarHourUseCase();
  const computeSceneLightingUseCase = ComputeSceneLightingUseCase();
  final generateTerrainLayoutUseCase = GenerateTerrainLayoutUseCase();
  const resolveCameraModeUseCase = ResolveCameraModeUseCase();

  final simulationProvider = SimulationProvider(
    getCelestialBodiesUseCase: getCelestialBodiesUseCase,
    simulateDescentStepUseCase: simulateDescentStepUseCase,
    evaluateSolarHourUseCase: evaluateSolarHourUseCase,
    computeSceneLightingUseCase: computeSceneLightingUseCase,
    generateTerrainLayoutUseCase: generateTerrainLayoutUseCase,
    resolveCameraModeUseCase: resolveCameraModeUseCase,
  );

  runApp(WeinSolarApp(simulationProvider: simulationProvider));
}

class WeinSolarApp extends StatelessWidget {
  static const Color weincodeIndigoDeep = Color(0xFF18084D);
  static const Color weincodeElectricViolet = Color(0xFF5236FF);
  static const Color weincodeSoftLavender = Color(0xFFA599FF);
  static const Color weincodePureWhite = Color(0xFFFFFFFF);

  final SimulationProvider simulationProvider;

  const WeinSolarApp({
    super.key,
    required this.simulationProvider,
  });

  static ThemeData buildWeincodeTheme() {
    const colorScheme = ColorScheme.dark(
      primary: weincodeElectricViolet,
      onPrimary: weincodePureWhite,
      secondary: weincodeSoftLavender,
      onSecondary: weincodeIndigoDeep,
      surface: weincodeIndigoDeep,
      onSurface: weincodePureWhite,
      error: weincodeSoftLavender,
      onError: weincodeIndigoDeep,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: weincodeIndigoDeep,
      colorScheme: colorScheme,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: weincodePureWhite),
        bodyMedium: TextStyle(color: weincodePureWhite),
        bodySmall: TextStyle(color: weincodeSoftLavender),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WeinSolar v2',
      debugShowCheckedModeBanner: false,
      theme: buildWeincodeTheme(),
      initialRoute: AppRoutes.simulator,
      routes: AppRoutes.buildRoutes(simulationProvider),
    );
  }
}
