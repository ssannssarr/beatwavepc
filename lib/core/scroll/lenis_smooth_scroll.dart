import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Lenis-inspired smooth scroll behavior and physics for BeatWave.
///
/// Features:
/// 1. Normalized wheel delta: Reduces the discrete jump distance per mouse wheel notch
///    by ~58% (scaling factor 0.42x) so scrolling is less aggressive and more controllable.
/// 2. Fluid momentum easing: Uses cubic ease-out interpolation (`Curves.easeOutCubic`)
///    with target offset accumulation, creating the signature silky Lenis glide effect.
/// 3. Native drag transparency: Preserves direct touch, trackpad, and scrollbar drag
///    without interfering with natural input.
class LenisScrollBehavior extends MaterialScrollBehavior {
  const LenisScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const LenisScrollPhysics();
  }

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    final wrappedChild = LenisSmoothScrollWrapper(
      controller: details.controller,
      direction: details.direction,
      child: child,
    );
    return super.buildScrollbar(context, wrappedChild, details);
  }
}

/// Custom scroll physics providing fast, smooth deceleration with bouncing overscroll.
class LenisScrollPhysics extends BouncingScrollPhysics {
  const LenisScrollPhysics({super.parent})
      : super(decelerationRate: ScrollDecelerationRate.fast);

  @override
  LenisScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return LenisScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // Keep user touch dragging crisp and direct
    return super.applyPhysicsToUserOffset(position, offset);
  }
}

/// A wrapper widget that intercepts mouse wheel pointer signals and performs
/// Lenis-style accumulated smooth interpolation.
class LenisSmoothScrollWrapper extends StatefulWidget {
  final Widget child;
  final ScrollController? controller;
  final AxisDirection direction;

  /// Sensitivity multiplier for mouse wheel delta.
  /// 0.42 means scrolling ~42% of the default native notch distance,
  /// fulfilling "scroll less at a time" while keeping it effortless.
  final double wheelDeltaMultiplier;

  /// Duration of the ease animation for each scroll step.
  final Duration animationDuration;

  /// Easing curve for the smooth momentum glide.
  final Curve curve;

  const LenisSmoothScrollWrapper({
    super.key,
    required this.child,
    this.controller,
    this.direction = AxisDirection.down,
    this.wheelDeltaMultiplier = 0.42,
    this.animationDuration = const Duration(milliseconds: 280),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<LenisSmoothScrollWrapper> createState() =>
      _LenisSmoothScrollWrapperState();
}

class _LenisSmoothScrollWrapperState extends State<LenisSmoothScrollWrapper> {
  double? _targetOffset;
  bool _isAnimating = false;

  ScrollPosition? _resolvePosition() {
    if (widget.controller?.hasClients == true) {
      return widget.controller!.position;
    }
    return Scrollable.maybeOf(context)?.position;
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;

    // Only intercept mouse wheel events where discrete jumps occur.
    // Native trackpads already send high-frequency continuous delta events.
    if (event.kind != PointerDeviceKind.mouse) return;

    final position = _resolvePosition();
    if (position == null) return;
    if (!position.hasContentDimensions) return;

    // Register our callback with highest priority in the pointerSignalResolver
    // so our smooth handler executes instead of the abrupt default forcePixels.
    GestureBinding.instance.pointerSignalResolver.register(
      event,
      (resolvedEvent) => _handlePointerScroll(resolvedEvent as PointerScrollEvent),
    );
  }

  void _handlePointerScroll(PointerScrollEvent event) {
    final position = _resolvePosition();
    if (position == null || !position.hasContentDimensions) return;

    final axis = axisDirectionToAxis(widget.direction);
    final rawDelta = axis == Axis.vertical ? event.scrollDelta.dy : event.scrollDelta.dx;
    if (rawDelta == 0.0) return;

    // Reverse if axis direction is inverted (e.g. up or left)
    final directedDelta =
        axisDirectionIsReversed(widget.direction) ? -rawDelta : rawDelta;

    // Apply multiplier to scroll less at a time
    final normalizedDelta = directedDelta * widget.wheelDeltaMultiplier;

    // If an animation is already in flight, accumulate target from the existing target;
    // otherwise begin from current pixels.
    final baseOffset = (_isAnimating && _targetOffset != null)
        ? _targetOffset!
        : position.pixels;

    final newTarget = (baseOffset + normalizedDelta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    _targetOffset = newTarget;

    // If already at boundary, no need to animate
    if ((newTarget - position.pixels).abs() < 0.5) {
      _isAnimating = false;
      return;
    }

    _isAnimating = true;
    position
        .animateTo(
          newTarget,
          duration: widget.animationDuration,
          curve: widget.curve,
        )
        .whenComplete(() {
          if (mounted) {
            _isAnimating = false;
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerSignal: _onPointerSignal,
      child: widget.child,
    );
  }
}
