import 'package:flutter/material.dart';

import '../../ui/pages/simulator_page.dart';
import '../providers/simulation_provider.dart';

class AppRoutes {
  static const String simulator = '/';

  static Map<String, WidgetBuilder> buildRoutes(SimulationProvider provider) {
    return {
      simulator: (context) => SimulatorPage(provider: provider),
    };
  }
}
