import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:fold_adaptive_nav_platform_interface/fold_adaptive_nav_platform_interface.dart';

import 'fold_geometry.dart';
import 'fold_media_query.dart';

/// The insets that keep [area] clear of [cameras], all in the same
/// coordinate space.
///
/// Each housing that overlaps [area] is cleared from the edge that needs the
/// least inset: a camera in the top corner pushes the top edge down, not the
/// side edge in.
EdgeInsets cameraInsets(Rect area, Iterable<Rect> cameras) {
  var left = 0.0, top = 0.0, right = 0.0, bottom = 0.0;
  for (final camera in cameras) {
    final overlap = camera.intersect(area);
    if (overlap.width <= 0 || overlap.height <= 0) continue;
    final fromTop = overlap.bottom - area.top;
    final fromBottom = area.bottom - overlap.top;
    final fromLeft = overlap.right - area.left;
    final fromRight = area.right - overlap.left;
    final least = [fromTop, fromBottom, fromLeft, fromRight].reduce(math.min);
    if (least == fromTop) {
      top = math.max(top, fromTop);
    } else if (least == fromBottom) {
      bottom = math.max(bottom, fromBottom);
    } else if (least == fromLeft) {
      left = math.max(left, fromLeft);
    } else {
      right = math.max(right, fromRight);
    }
  }
  return EdgeInsets.fromLTRB(left, top, right, bottom);
}

/// A [SafeArea] that also keeps [child] clear of the camera and sensor
/// housings the platform reports as [RegionKind.cameraOcclusion] regions,
/// such as the iPhone Duo's on its cover display.
///
/// Only housings over this widget count, so one under an app bar doesn't pad
/// the body below it. To keep content off the fold, use `FoldSplitView`.
class FoldSafeArea extends StatefulWidget {
  const FoldSafeArea({
    super.key,
    required this.child,
    this.left = true,
    this.top = true,
    this.right = true,
    this.bottom = true,
    this.minimum = EdgeInsets.zero,
  });

  final Widget child;
  final bool left;
  final bool top;
  final bool right;
  final bool bottom;
  final EdgeInsets minimum;

  @override
  State<FoldSafeArea> createState() => _FoldSafeAreaState();
}

class _FoldSafeAreaState extends State<FoldSafeArea> with FoldRectTracker {
  @override
  Widget build(BuildContext context) {
    final cameras = [
      for (final region in FoldMediaQuery.regionsOf(context))
        if (region.kind == RegionKind.cameraOcclusion) region.bounds,
    ];
    final data = MediaQuery.of(context);
    var insets = EdgeInsets.zero;
    if (cameras.isNotEmpty) {
      trackRect();
      insets = cameraInsets(trackedRect ?? Offset.zero & data.size, cameras);
    }
    final padding = data.padding;
    // Always the same tree, so the child keeps its state when housings
    // appear or go.
    return MediaQuery(
      data: data.copyWith(
        padding: EdgeInsets.fromLTRB(
          math.max(padding.left, insets.left),
          math.max(padding.top, insets.top),
          math.max(padding.right, insets.right),
          math.max(padding.bottom, insets.bottom),
        ),
      ),
      child: SafeArea(
        left: widget.left,
        top: widget.top,
        right: widget.right,
        bottom: widget.bottom,
        minimum: widget.minimum,
        child: widget.child,
      ),
    );
  }
}
