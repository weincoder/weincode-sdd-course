import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../config/providers/simulation_provider.dart';
import '../../domain/models/scene/camera_mode.dart';
import '../widgets/mission_outcome_overlay.dart';
import '../widgets/scene3d/planetary_scene_view.dart';
import '../widgets/scene3d/scene_descriptor_mapper.dart';
import '../widgets/solar_hour_control_panel.dart';
import '../widgets/thruster_control_button.dart';
import '../widgets/weincode_cockpit_hud.dart';
import '../widgets/world_selector_sheet.dart';

class SimulatorPage extends StatefulWidget {
  static const Color weincodeIndigoDeep = Color(0xFF18084D);
  static const Color weincodeElectricViolet = Color(0xFF5236FF);
  static const Color weincodeSoftLavender = Color(0xFFA599FF);
  static const Color weincodePureWhite = Color(0xFFFFFFFF);

  final SimulationProvider provider;
  final Widget Function(SceneDescriptor descriptor)? sceneBuilder;

  const SimulatorPage({
    super.key,
    required this.provider,
    this.sceneBuilder,
  });

  @override
  State<SimulatorPage> createState() => _SimulatorPageState();
}

class _SimulatorPageState extends State<SimulatorPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  final FocusNode _keyboardFocusNode = FocusNode();
  Duration? _lastElapsed;
  bool _areControlsHidden = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_onTick);
    widget.provider.addListener(_syncTickerWithState);

    if (widget.provider.worlds.isEmpty && !widget.provider.isLoading) {
      widget.provider.loadWorlds();
    }
    _syncTickerWithState();
  }

  void _syncTickerWithState() {
    final shouldTick =
        widget.provider.isDescending && !widget.provider.isPaused;
    if (shouldTick && !_ticker.isActive) {
      _lastElapsed = null;
      _ticker.start();
    } else if (!shouldTick && _ticker.isActive) {
      _ticker.stop();
      _lastElapsed = null;
    }
  }

  void _onTick(Duration elapsed) {
    final previous = _lastElapsed;
    _lastElapsed = elapsed;
    if (previous == null) {
      return;
    }
    final deltaSeconds = (elapsed - previous).inMicroseconds / 1000000.0;
    if (deltaSeconds > 0.0) {
      widget.provider.stepSimulation(deltaSeconds);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _lastElapsed = null;
      widget.provider.setPaused(false);
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _lastElapsed = null;
      widget.provider.setPaused(true);
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;

    if (widget.provider.cameraMode == CameraMode.orbit &&
        (event is KeyDownEvent || event is KeyRepeatEvent)) {
      if (key == LogicalKeyboardKey.arrowLeft) {
        widget.provider.rotateCameraByDelta(-5.0);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowRight) {
        widget.provider.rotateCameraByDelta(5.0);
        return KeyEventResult.handled;
      }
    }

    final isThrusterKey = key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.arrowUp;
    if (!isThrusterKey) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      widget.provider.setThrusterActive(true);
      return KeyEventResult.handled;
    } else if (event is KeyUpEvent) {
      widget.provider.setThrusterActive(false);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _toggleControlsVisibility() {
    setState(() {
      _areControlsHidden = !_areControlsHidden;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.provider.removeListener(_syncTickerWithState);
    _ticker.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SimulatorPage.weincodeIndigoDeep,
      body: SafeArea(
        child: Focus(
          focusNode: _keyboardFocusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: ListenableBuilder(
            listenable: widget.provider,
            builder: (context, _) {
              if (widget.provider.isWorldSelectionActive) {
                return WorldSelectorSheet(
                  worlds: widget.provider.worlds,
                  visualQuality: widget.provider.visualQuality,
                  onQualityChanged: widget.provider.setVisualQuality,
                  onSelectWorld: (world) {
                    setState(() {
                      _areControlsHidden = false;
                    });
                    widget.provider.selectWorld(world);
                    _keyboardFocusNode.requestFocus();
                  },
                );
              }

              final world = widget.provider.selectedWorld!;
              final landerState = widget.provider.landerState!;
              final attempt = widget.provider.missionAttempt!;
              final solarHourState = widget.provider.solarHourState;
              final descriptor = widget.provider.sceneDescriptor!;

              return Stack(
                fit: StackFit.expand,
                children: [
                  // 3D Planetary Scene Viewport (isolated from Weincode palette per FR-021 / RN-10)
                  if (widget.sceneBuilder != null)
                    widget.sceneBuilder!(descriptor)
                  else
                    PlanetarySceneView(
                      key: const Key('planetary-scene-3d-canvas'),
                      descriptor: descriptor,
                      onOrbitAzimuthDelta: widget.provider.rotateCameraByDelta,
                    ),

                  // Top Weincode Cockpit HUD Overlay (FR-019..FR-021, FR-026)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 880),
                        child: WeincodeCockpitHud(
                          world: world,
                          landerState: landerState,
                          isAutopilotActive: widget.provider.isAutopilotActive,
                          onToggleAutoLand: widget.provider.toggleAutoLand,
                          onResetInFlight: widget.provider.resetInFlight,
                          visualQuality: widget.provider.visualQuality,
                          onQualityChanged: widget.provider.setVisualQuality,
                          areControlsHidden: _areControlsHidden,
                          onToggleControlsVisibility: _toggleControlsVisibility,
                        ),
                      ),
                    ),
                  ),

                  // Bottom Controls: Thruster during descent, Outcome & Solar Hour after completion
                  Positioned(
                    bottom: 14,
                    left: 12,
                    right: 12,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 780),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.provider.isSolarHourUnlocked) ...[
                              SolarHourControlPanel(
                                world: world,
                                solarHourState: solarHourState,
                                onElevationChanged:
                                    widget.provider.updateSolarElevation,
                              ),
                              if (!_areControlsHidden)
                                const SizedBox(height: 10),
                            ],
                            if (widget.provider.isDescending)
                              ThrusterControlButton(
                                isThrusterActive: landerState.isThrusterActive,
                                isOutOfFuel: landerState.isOutOfFuel,
                                isEnabled: widget.provider.isDescending,
                                onThrusterChanged:
                                    widget.provider.setThrusterActive,
                              )
                            else if (!_areControlsHidden)
                              MissionOutcomeOverlay(
                                world: world,
                                attempt: attempt,
                                onRetry: widget.provider.retryCurrentWorld,
                                onChangeWorld:
                                    widget.provider.returnToWorldSelection,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
