import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsx_plus/iconsx_plus.dart';

import 'package:beatwave/blocs/media_player/beatwave_player_cubit.dart';
import 'package:beatwave/blocs/settings_cubit/cubit/settings_cubit.dart';
import 'package:beatwave/core/theme/app_theme.dart';
import 'package:beatwave/l10n/app_localizations.dart';

/// Displays the 8D Audio Spatializer interactive control sheet.
void showEightDAudioSheet(BuildContext context) {
  final playerCubit = context.read<BeatWavePlayerCubit>();
  final settingsCubit = context.read<SettingsCubit>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    elevation: 0,
    constraints: const BoxConstraints(maxWidth: 520),
    builder: (sheetContext) {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: playerCubit),
          BlocProvider.value(value: settingsCubit),
        ],
        child: const _EightDAudioSheetBody(),
      );
    },
  );
}

class _EightDAudioSheetBody extends StatefulWidget {
  const _EightDAudioSheetBody();

  @override
  State<_EightDAudioSheetBody> createState() => _EightDAudioSheetBodyState();
}

class _EightDAudioSheetBodyState extends State<_EightDAudioSheetBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbitController;

  @override
  void initState() {
    super.initState();
    final player = context.read<BeatWavePlayerCubit>().beatwavePlayer;
    final initialSpeed = player.eightDSpeed.clamp(0.02, 0.50);
    final initialDuration = Duration(
      milliseconds: ((1.0 / initialSpeed) * 1000).round(),
    );

    _orbitController = AnimationController(
      vsync: this,
      duration: initialDuration,
    );

    if (player.eightDEnabled) {
      _orbitController.repeat();
    }
  }

  @override
  void dispose() {
    _orbitController.dispose();
    super.dispose();
  }

  void _updateControllerPeriod(double speed, bool isEnabled) {
    final periodMs = ((1.0 / speed.clamp(0.02, 0.50)) * 1000).round();
    final newDuration = Duration(milliseconds: periodMs);
    if (_orbitController.duration != newDuration) {
      final prevVal = _orbitController.value;
      _orbitController.duration = newDuration;
      if (isEnabled) {
        _orbitController.forward(from: prevVal);
        _orbitController.repeat();
      }
    }
  }

  Future<void> _toggleEightD(bool enabled) async {
    final player = context.read<BeatWavePlayerCubit>().beatwavePlayer;
    final settingsCubit = context.read<SettingsCubit>();

    await player.setEightDEnabled(enabled);
    settingsCubit.setEightDEnabled(enabled);

    if (enabled) {
      _orbitController.repeat();
    } else {
      _orbitController.stop();
    }
  }

  Future<void> _setSpeed(double speed) async {
    final player = context.read<BeatWavePlayerCubit>().beatwavePlayer;
    final settingsCubit = context.read<SettingsCubit>();

    final clamped = speed.clamp(0.04, 0.20);
    await player.setEightDSpeed(clamped);
    settingsCubit.setEightDSpeed(clamped);

    _updateControllerPeriod(clamped, player.eightDEnabled);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final player = context.read<BeatWavePlayerCubit>().beatwavePlayer;
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        10,
        0,
        10,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Default_Theme.themeColor.withValues(alpha: 0.96),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: StreamBuilder<bool>(
                stream: player.eightDEnabledStream,
                initialData: player.eightDEnabled,
                builder: (context, enabledSnapshot) {
                  final isEnabled = enabledSnapshot.data ?? false;

                  return StreamBuilder<double>(
                    stream: player.eightDSpeedStream,
                    initialData: player.eightDSpeed,
                    builder: (context, speedSnapshot) {
                      final currentSpeed = speedSnapshot.data ?? 0.10;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeader(context, l10n, isEnabled),
                          Flexible(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // 360° Spatial Visualizer
                                  Center(
                                    child: _SpatialOrbitVisualizer(
                                      orbitAnimation: _orbitController,
                                      isEnabled: isEnabled,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Master Toggle Card
                                  _buildMasterToggleCard(
                                    context,
                                    l10n,
                                    isEnabled,
                                  ),
                                  const SizedBox(height: 14),

                                  // Presets row
                                  _buildPresetsSection(
                                    context,
                                    l10n,
                                    currentSpeed,
                                    isEnabled,
                                  ),
                                  const SizedBox(height: 14),

                                  // Fine-tuning speed slider
                                  _buildSpeedSliderSection(
                                    context,
                                    l10n,
                                    currentSpeed,
                                    isEnabled,
                                  ),
                                  const SizedBox(height: 14),

                                  // Headphones recommendation tip
                                  _buildTipBanner(context, l10n),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    bool isEnabled,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEnabled
                  ? Default_Theme.accentColor1.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.spatial_audio_rounded,
              color: isEnabled
                  ? Default_Theme.accentColor1
                  : Default_Theme.primaryColor1.withValues(alpha: 0.6),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.playerSettingEightD,
                  style: const TextStyle(
                    color: Default_Theme.primaryColor1,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ).merge(Default_Theme.secondoryTextStyle),
                ),
                Text(
                  l10n.playerSettingEightDSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Default_Theme.primaryColor1.withValues(alpha: 0.6),
                    fontSize: 12,
                  ).merge(Default_Theme.secondoryTextStyle),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              MingCute.close_line,
              color: Default_Theme.primaryColor1,
              size: 22,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterToggleCard(
    BuildContext context,
    AppLocalizations l10n,
    bool isEnabled,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isEnabled
            ? Default_Theme.accentColor1.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled
              ? Default_Theme.accentColor1.withValues(alpha: 0.40)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '360° Dynamic Rotation',
                      style: const TextStyle(
                        color: Default_Theme.primaryColor1,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ).merge(Default_Theme.secondoryTextStyle),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? Default_Theme.accentColor1
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isEnabled ? 'ACTIVE' : 'OFF',
                        style: TextStyle(
                          color: isEnabled
                              ? Colors.black
                              : Default_Theme.primaryColor1
                                  .withValues(alpha: 0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isEnabled
                      ? 'Audio orbits around your head in real time'
                      : 'Stereo passthrough without spatial panning',
                  style: TextStyle(
                    color: Default_Theme.primaryColor1.withValues(alpha: 0.6),
                    fontSize: 12,
                  ).merge(Default_Theme.secondoryTextStyle),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            activeThumbColor: Default_Theme.accentColor1,
            activeTrackColor:
                Default_Theme.accentColor1.withValues(alpha: 0.35),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white12,
            onChanged: _toggleEightD,
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsSection(
    BuildContext context,
    AppLocalizations l10n,
    double currentSpeed,
    bool isEnabled,
  ) {
    // Presets: Slow (0.07 Hz ~14s), Normal (0.10 Hz ~10s), Fast (0.14 Hz ~7s)
    final presets = [
      (0.07, l10n.playerSettingEightDSlow, '14s'),
      (0.10, l10n.playerSettingEightDNormal, '10s'),
      (0.14, l10n.playerSettingEightDFast, '7s'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rotation Speed Presets',
          style: TextStyle(
            color: Default_Theme.primaryColor1.withValues(alpha: 0.8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ).merge(Default_Theme.secondoryTextStyle),
        ),
        const SizedBox(height: 8),
        Row(
          children: presets.map((p) {
            final (speed, label, time) = p;
            final isSelected = (currentSpeed - speed).abs() < 0.015;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: InkWell(
                  onTap: isEnabled ? () => _setSpeed(speed) : null,
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected && isEnabled
                          ? Default_Theme.accentColor1.withValues(alpha: 0.20)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected && isEnabled
                            ? Default_Theme.accentColor1
                            : Colors.white.withValues(alpha: 0.08),
                        width: isSelected && isEnabled ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            color: isSelected && isEnabled
                                ? Default_Theme.accentColor1
                                : Default_Theme.primaryColor1.withValues(
                                    alpha: isEnabled ? 0.9 : 0.4),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ).merge(Default_Theme.secondoryTextStyle),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label.split(' ').first,
                          style: TextStyle(
                            color: Default_Theme.primaryColor1.withValues(
                                alpha: isEnabled ? 0.6 : 0.3),
                            fontSize: 11,
                          ).merge(Default_Theme.secondoryTextStyle),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSpeedSliderSection(
    BuildContext context,
    AppLocalizations l10n,
    double currentSpeed,
    bool isEnabled,
  ) {
    final periodSeconds = (1.0 / currentSpeed).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Orbit Period',
                style: TextStyle(
                  color: Default_Theme.primaryColor1.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ).merge(Default_Theme.secondoryTextStyle),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? Default_Theme.accentColor1.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${periodSeconds}s / rev (${currentSpeed.toStringAsFixed(2)} Hz)',
                  style: TextStyle(
                    color: isEnabled
                        ? Default_Theme.accentColor1
                        : Default_Theme.primaryColor1.withValues(alpha: 0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: isEnabled
                  ? Default_Theme.accentColor1
                  : Default_Theme.primaryColor1.withValues(alpha: 0.2),
              inactiveTrackColor: Colors.white12,
              thumbColor: isEnabled
                  ? Default_Theme.accentColor1
                  : Default_Theme.primaryColor1.withValues(alpha: 0.4),
              overlayColor:
                  Default_Theme.accentColor1.withValues(alpha: 0.15),
              trackHeight: 4,
            ),
            child: Slider(
              value: currentSpeed.clamp(0.04, 0.20),
              min: 0.04,
              max: 0.20,
              divisions: 16,
              onChanged: isEnabled ? (val) => _setSpeed(val) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipBanner(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.blueAccent.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.headphones_rounded,
              color: Colors.lightBlueAccent,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.playerSettingEightDHeadphonesTip,
              style: TextStyle(
                color: Colors.lightBlueAccent.withValues(alpha: 0.9),
                fontSize: 12,
                height: 1.35,
              ).merge(Default_Theme.secondoryTextStyle),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 360° Spatial Orbit Visualizer ──────────────────────────────────────────

class _SpatialOrbitVisualizer extends StatelessWidget {
  final Animation<double> orbitAnimation;
  final bool isEnabled;

  const _SpatialOrbitVisualizer({
    required this.orbitAnimation,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    const size = 180.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Orbit dashed rings
          CustomPaint(
            size: const Size(size, size),
            painter: _OrbitRingPainter(
              isEnabled: isEnabled,
              primaryColor: Default_Theme.accentColor1,
            ),
          ),

          // Left & Right Ear channel markers
          Positioned(
            left: 12,
            child: _ChannelBadge(label: 'L', isEnabled: isEnabled),
          ),
          Positioned(
            right: 12,
            child: _ChannelBadge(label: 'R', isEnabled: isEnabled),
          ),

          // Central listener head
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEnabled
                  ? Default_Theme.accentColor1.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: isEnabled
                    ? Default_Theme.accentColor1.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color:
                            Default_Theme.accentColor1.withValues(alpha: 0.25),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.headphones_rounded,
              color: isEnabled
                  ? Default_Theme.accentColor1
                  : Default_Theme.primaryColor1.withValues(alpha: 0.4),
              size: 28,
            ),
          ),

          // Orbiting sound emitter node
          AnimatedBuilder(
            animation: orbitAnimation,
            builder: (context, child) {
              final angle = isEnabled
                  ? orbitAnimation.value * 2 * math.pi
                  : -math.pi / 2;
              const radius = (size / 2) - 18;
              final x = radius * math.cos(angle);
              final y = radius * math.sin(angle);

              return Transform.translate(
                offset: Offset(x, y),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isEnabled
                        ? Default_Theme.accentColor1
                        : Colors.white.withValues(alpha: 0.2),
                    boxShadow: isEnabled
                        ? [
                            BoxShadow(
                              color: Default_Theme.accentColor1
                                  .withValues(alpha: 0.7),
                              blurRadius: 12,
                              spreadRadius: 3,
                            ),
                          ]
                        : null,
                  ),
                  child: const Center(
                    child: Icon(
                      MingCute.volume_fill,
                      color: Colors.black,
                      size: 13,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChannelBadge extends StatelessWidget {
  final String label;
  final bool isEnabled;

  const _ChannelBadge({required this.label, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isEnabled
            ? Default_Theme.accentColor1.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isEnabled
                ? Default_Theme.accentColor1
                : Default_Theme.primaryColor1.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _OrbitRingPainter extends CustomPainter {
  final bool isEnabled;
  final Color primaryColor;

  _OrbitRingPainter({required this.isEnabled, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 18;

    final paint = Paint()
      ..color = isEnabled
          ? primaryColor.withValues(alpha: 0.25)
          : Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw full orbit ring
    canvas.drawCircle(center, radius, paint);

    // Subtle inner depth ring
    final innerPaint = Paint()
      ..color = isEnabled
          ? primaryColor.withValues(alpha: 0.10)
          : Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius - 24, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter oldDelegate) {
    return oldDelegate.isEnabled != isEnabled ||
        oldDelegate.primaryColor != primaryColor;
  }
}
