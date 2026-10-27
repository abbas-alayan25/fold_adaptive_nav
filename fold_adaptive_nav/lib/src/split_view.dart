import 'package:flutter/widgets.dart';
import 'package:fold_adaptive_nav_platform_interface/fold_adaptive_nav_platform_interface.dart';

import 'config.dart';
import 'fold_geometry.dart';
import 'fold_media_query.dart';
import 'form_factor.dart';

/// When a [FoldSplitView] shows two panes.
enum FoldSplitMode {
  /// Only at a real fold: a book foldable opened flat or half open (side by
  /// side), or any foldable half open with the fold across (top and bottom).
  hinge,

  /// As [hinge], and also side by side in tablet windows at least
  /// `FoldAdaptiveConfig.expandedBreakpoint` wide. The default.
  hingeOrWide,

  /// Only half open with the fold across: tabletop on a book foldable held
  /// sideways, or Flex mode on a flip phone.
  tabletop,
}

/// Where a [FoldSplitView] divides its area.
@immutable
class FoldSplit {
  const FoldSplit({required this.axis, required this.start, required this.end});

  /// [Axis.horizontal]: panes side by side. [Axis.vertical]: one on top of
  /// the other.
  final Axis axis;

  /// Where the first pane ends and the second begins, in logical pixels from
  /// the area's physical left (or top). The space between is the fold.
  final double start;
  final double end;

  @override
  bool operator ==(Object other) =>
      other is FoldSplit &&
      other.axis == axis &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(axis, start, end);

  @override
  String toString() => 'FoldSplit(${axis.name}, $start–$end)';
}

/// Decides how [FoldSplitView] divides [area], which is in the coordinate
/// space of the fold regions. Null means one pane.
///
/// A fold only splits the area it runs through. A flat fold across the
/// display (an opened flip phone) doesn't split: it's one screen.
FoldSplit? resolveFoldSplit({
  required Rect area,
  required FoldState fold,
  required FormFactor formFactor,
  FoldAdaptiveConfig config = const FoldAdaptiveConfig(),
  FoldSplitMode mode = FoldSplitMode.hingeOrWide,
  double wideSplit = 0.5,
}) {
  final halfOpen = fold.posture == HingePosture.partiallyOpen;
  final open = halfOpen || fold.posture == HingePosture.fullyOpen;
  if (fold.isFoldable && open) {
    for (final region in fold.folds) {
      final bounds = region.bounds.shift(-area.topLeft);
      if (bounds.width == 0 && bounds.height == 0) continue;
      // A fold taller than wide runs down the display: panes side by side.
      final down = bounds.height > bounds.width;
      if (down ? mode == FoldSplitMode.tabletop : !halfOpen) continue;
      final (start, end, extent) = down
          ? (bounds.left, bounds.right, area.width)
          : (bounds.top, bounds.bottom, area.height);
      if (start <= 0 || end >= extent) continue; // Not through this area.
      return FoldSplit(
        axis: down ? Axis.horizontal : Axis.vertical,
        start: start,
        end: end,
      );
    }
  }
  if (mode == FoldSplitMode.hingeOrWide &&
      formFactor == FormFactor.tablet &&
      area.width >= config.expandedBreakpoint) {
    final at = area.width * wideSplit;
    return FoldSplit(axis: Axis.horizontal, start: at, end: at);
  }
  return null;
}

/// Builds the one-pane layout of a [FoldSplitView] from its two panes.
typedef SinglePaneBuilder = Widget Function(
  BuildContext context,
  Widget start,
  Widget end,
);

/// Two panes divided at the fold, or one pane where there is none.
///
/// | Device | Shows |
/// |---|---|
/// | Book foldable, opened (flat or half open) | [start] \| [end] at the fold |
/// | Half open, fold across (tabletop, Flex mode) | [start] above, [end] below the fold |
/// | Tablet window from 840 pt wide ([FoldSplitMode.hingeOrWide]) | [start] \| [end] at [wideSplit] |
/// | Anything else | [singleBuilder], by default [start] alone |
///
/// [start] and [end] keep their state while the layout changes, as long as
/// [singleBuilder] keeps them in the tree. In right-to-left locales [start]
/// is on the right.
///
/// Fold regions are in screen coordinates. The view measures where it sits
/// after the first frame; until then it assumes it fills the screen, which
/// is where it usually goes. Give it bounded constraints.
class FoldSplitView extends StatefulWidget {
  const FoldSplitView({
    super.key,
    required this.start,
    required this.end,
    this.mode = FoldSplitMode.hingeOrWide,
    this.wideSplit = 0.5,
    this.singleBuilder,
  }) : assert(wideSplit > 0 && wideSplit < 1);

  final Widget start;
  final Widget end;
  final FoldSplitMode mode;

  /// The fraction of the width [start] takes in a wide window without a fold.
  final double wideSplit;

  /// Lays out the panes when there is no split. Defaults to [start] alone,
  /// which drops [end] and its state; for a list and detail, return [end]
  /// while an item is open.
  final SinglePaneBuilder? singleBuilder;

  /// Whether [context] is in a pane shown beside (or above) the other one.
  /// False in the one-pane layout and outside a [FoldSplitView]; use it to
  /// show a back button only when a pane is alone.
  static bool isSplitOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SplitScope>()?.split ?? false;

  @override
  State<FoldSplitView> createState() => _FoldSplitViewState();
}

class _SplitScope extends InheritedWidget {
  const _SplitScope({required this.split, required super.child});

  final bool split;

  @override
  bool updateShouldNotify(_SplitScope oldWidget) => split != oldWidget.split;
}

class _FoldSplitViewState extends State<FoldSplitView> with FoldRectTracker {
  final _startKey = GlobalKey(debugLabel: 'FoldSplitView.start');
  final _endKey = GlobalKey(debugLabel: 'FoldSplitView.end');

  @override
  Widget build(BuildContext context) {
    // Only the aspects the split depends on, not every hinge-angle snapshot.
    final regions = FoldMediaQuery.regionsOf(context);
    final fold = FoldState.unsupported.copyWith(
      isFoldable: FoldMediaQuery.isFoldableOf(context),
      posture: FoldMediaQuery.postureOf(context),
      regions: regions,
    );
    final formFactor = context.formFactor;
    final config = FoldMediaQuery.configOf(context);
    if (fold.folds.isNotEmpty) trackRect();

    final start = KeyedSubtree(key: _startKey, child: widget.start);
    final end = KeyedSubtree(key: _endKey, child: widget.end);
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      final origin = trackedRect?.topLeft ?? Offset.zero;
      final split = resolveFoldSplit(
        area: origin & size,
        fold: fold,
        formFactor: formFactor,
        config: config,
        mode: widget.mode,
        wideSplit: widget.wideSplit,
      );
      return _SplitScope(
        split: split != null,
        child: split == null
            ? (widget.singleBuilder ?? _startOnly)(context, start, end)
            : _panes(context, split, start, end),
      );
    });
  }

  static Widget _startOnly(BuildContext context, Widget start, Widget end) =>
      start;

  Widget _panes(
      BuildContext context, FoldSplit split, Widget start, Widget end) {
    final ambient = Directionality.of(context);
    Widget pane(Widget child, {required bool first}) =>
        MediaQuery.removePadding(
          context: context,
          removeRight: split.axis == Axis.horizontal && first,
          removeLeft: split.axis == Axis.horizontal && !first,
          removeBottom: split.axis == Axis.vertical && first,
          removeTop: split.axis == Axis.vertical && !first,
          child: Directionality(textDirection: ambient, child: child),
        );

    if (split.axis == Axis.vertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: split.start, child: pane(start, first: true)),
          SizedBox(height: split.end - split.start),
          Expanded(child: pane(end, first: false)),
        ],
      );
    }
    final rtl = ambient == TextDirection.rtl;
    return Row(
      textDirection: TextDirection.ltr,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
            width: split.start, child: pane(rtl ? end : start, first: true)),
        SizedBox(width: split.end - split.start),
        Expanded(child: pane(rtl ? start : end, first: false)),
      ],
    );
  }
}

/// [top] above the fold and [bottom] below it while the device stands half
/// open with the fold across: a video above its controls, a camera preview
/// above the shutter.
///
/// Otherwise [flatBuilder] lays them out, by default [top] filling the space
/// above [bottom]. Both keep their state across the change, so a video
/// keeps playing.
class TabletopLayout extends StatelessWidget {
  const TabletopLayout({
    super.key,
    required this.top,
    required this.bottom,
    this.flatBuilder,
  });

  final Widget top;
  final Widget bottom;
  final SinglePaneBuilder? flatBuilder;

  /// Whether [fold] is in the tabletop posture: half open, fold across.
  static bool isTabletop(FoldState fold) =>
      fold.isFoldable &&
      fold.posture == HingePosture.partiallyOpen &&
      fold.folds.any((f) => f.bounds.width > f.bounds.height);

  @override
  Widget build(BuildContext context) {
    return FoldSplitView(
      mode: FoldSplitMode.tabletop,
      start: top,
      end: bottom,
      singleBuilder: flatBuilder ?? _stacked,
    );
  }

  static Widget _stacked(BuildContext context, Widget top, Widget bottom) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Expanded(child: top), bottom],
      );
}
