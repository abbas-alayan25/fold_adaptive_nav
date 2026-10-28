import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Marks the box that [FoldRegion] bounds are measured from. Without one,
/// they are measured from the view, as the platform reports them.
///
/// `FoldPreview` puts one around its simulated screen.
class FoldCoordinateSpace extends InheritedWidget {
  /// Measures fold regions from the box that [rootKey] is on.
  const FoldCoordinateSpace({
    super.key,
    required this.rootKey,
    required super.child,
  });

  /// The key of the box at the coordinate space's origin.
  final GlobalKey rootKey;

  /// The box of the nearest [FoldCoordinateSpace], or null to measure from
  /// the view.
  static RenderObject? rootOf(BuildContext context) => context
      .getInheritedWidgetOfExactType<FoldCoordinateSpace>()
      ?.rootKey
      .currentContext
      ?.findRenderObject();

  @override
  bool updateShouldNotify(FoldCoordinateSpace oldWidget) =>
      rootKey != oldWidget.rootKey;
}

/// Keeps [trackedRect], the widget's own rect in the coordinate space of the
/// fold regions, up to date.
///
/// The rect is only known after layout, so it is read after each frame that
/// calls [trackRect] and the widget rebuilds once if it moved. Until then it
/// is null; callers assume the widget fills the screen.
mixin FoldRectTracker<T extends StatefulWidget> on State<T> {
  /// The widget's rect, or null before its first layout.
  Rect? trackedRect;

  /// Call from `build` while the layout depends on [trackedRect].
  void trackRect() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.hasSize || !box.attached) return;
      final root = FoldCoordinateSpace.rootOf(context);
      final rect = box.localToGlobal(Offset.zero, ancestor: root) & box.size;
      if (rect != trackedRect) setState(() => trackedRect = rect);
    });
  }
}
