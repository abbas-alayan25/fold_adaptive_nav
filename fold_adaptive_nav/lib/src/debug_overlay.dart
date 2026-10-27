import 'package:flutter/widgets.dart';
import 'package:fold_adaptive_nav_platform_interface/fold_adaptive_nav_platform_interface.dart';

import 'adaptive_values.dart';
import 'fold_geometry.dart';
import 'fold_media_query.dart';

/// Draws what the package sees over [child]: the form factor, posture,
/// hinge angle, window size and size classes in a label, the fold in red
/// and camera housings in orange. It doesn't take touches.
///
/// Put it in `MaterialApp.builder`, and turn it off in release builds:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) =>
///       FoldDebugOverlay(enabled: kDebugMode, child: child!),
/// )
/// ```
class FoldDebugOverlay extends StatefulWidget {
  const FoldDebugOverlay({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<FoldDebugOverlay> createState() => _FoldDebugOverlayState();
}

class _FoldDebugOverlayState extends State<FoldDebugOverlay>
    with FoldRectTracker {
  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return Stack(
        alignment: Alignment.topLeft,
        fit: StackFit.passthrough,
        children: [widget.child],
      );
    }
    final state = FoldMediaQuery.stateOf(context);
    final formFactor = FoldMediaQuery.formFactorOf(context);
    final size = MediaQuery.sizeOf(context);
    if (state.regions.isNotEmpty) trackRect();

    final angle = state.hingeAngle;
    final sizeClasses = state.horizontalSizeClass == SizeClass.unspecified
        ? null
        : '${state.horizontalSizeClass.name}/${state.verticalSizeClass.name}';
    final label = [
      formFactor.name,
      state.posture.name,
      if (angle != null) '${angle.round()}°',
      '${size.width.round()}×${size.height.round()}',
      context.windowSizeClass.name,
      if (sizeClasses != null) sizeClasses,
    ].join(' · ');

    // Same Stack either way, so turning it on keeps the app's state. A
    // non-directional alignment works above `MaterialApp`, too.
    return Stack(
      alignment: Alignment.topLeft,
      fit: StackFit.passthrough,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _RegionPainter(
                state.regions,
                trackedRect?.topLeft ?? Offset.zero,
              ),
            ),
          ),
        ),
        Positioned(
          left: 8,
          top: MediaQuery.paddingOf(context).top + 4,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xB3000000),
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Text(
                  label,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 11,
                    fontFamily: 'monospace',
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RegionPainter extends CustomPainter {
  _RegionPainter(this.regions, this.origin);

  final List<FoldRegion> regions;
  final Offset origin;

  @override
  void paint(Canvas canvas, Size size) {
    for (final region in regions) {
      final bounds = region.bounds.shift(-origin);
      final color = region.kind == RegionKind.fold
          ? const Color(0x66FF1744)
          : const Color(0x66FF9100);
      // Zero-width folds still get a visible line.
      final visible = Rect.fromCenter(
        center: bounds.center,
        width: bounds.width < 2 ? 2 : bounds.width,
        height: bounds.height < 2 ? 2 : bounds.height,
      );
      canvas.drawRect(visible, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_RegionPainter oldDelegate) =>
      oldDelegate.origin != origin ||
      !_sameRegions(oldDelegate.regions, regions);

  static bool _sameRegions(List<FoldRegion> a, List<FoldRegion> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
