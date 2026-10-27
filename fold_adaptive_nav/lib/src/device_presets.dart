import 'package:flutter/widgets.dart';
import 'package:fold_adaptive_nav_platform_interface/fold_adaptive_nav_platform_interface.dart';

import 'config.dart';
import 'fold_geometry.dart';
import 'fold_media_query.dart';
import 'form_factor.dart';

/// A screen and fold state to render an app on without the device: for
/// widget tests, golden tests and previews, through [FoldPreview].
///
/// The sizes are in logical pixels and approximate: close enough to pick
/// the same layout as the device, not a replacement for testing on it.
@immutable
class FoldDevicePreset {
  const FoldDevicePreset({
    required this.name,
    required this.size,
    required this.state,
    this.padding = EdgeInsets.zero,
  });

  final String name;
  final Size size;
  final FoldState state;

  /// The system bars' safe area.
  final EdgeInsets padding;

  /// The same screen turned a quarter, its fold and padding with it. A fold
  /// running down becomes one running across; posture is kept.
  FoldDevicePreset get rotated => FoldDevicePreset(
        name: '$name, rotated',
        size: size.flipped,
        padding: EdgeInsets.fromLTRB(
            padding.top, padding.right, padding.bottom, padding.left),
        state: state.copyWith(regions: [
          for (final r in state.regions)
            FoldRegion(
              kind: r.kind,
              isActive: r.isActive,
              bounds: Rect.fromLTRB(
                r.bounds.top,
                size.width - r.bounds.right,
                r.bounds.bottom,
                size.width - r.bounds.left,
              ),
            ),
        ]),
      );

  static const _iosBars = EdgeInsets.only(top: 59, bottom: 34);
  static const _androidBars = EdgeInsets.only(top: 24, bottom: 16);

  /// An ordinary phone (iPhone 16 size), not a foldable.
  static const phone = FoldDevicePreset(
    name: 'Phone',
    size: Size(393, 852),
    padding: _iosBars,
    state: FoldState.unsupported,
  );

  /// A small tablet (iPad mini size), not a foldable.
  static const tablet = FoldDevicePreset(
    name: 'Tablet',
    size: Size(744, 1133),
    padding: EdgeInsets.only(top: 24, bottom: 20),
    state: FoldState(
      isFoldable: false,
      posture: HingePosture.unknown,
      hingeAngle: null,
      regions: [],
      horizontalSizeClass: SizeClass.regular,
      verticalSizeClass: SizeClass.regular,
    ),
  );

  static const iPhoneDuoCover = FoldDevicePreset(
    name: 'iPhone Duo, closed',
    size: Size(466, 678),
    padding: EdgeInsets.only(top: 24, bottom: 20),
    state: _closed,
  );

  static const iPhoneDuoOpen = FoldDevicePreset(
    name: 'iPhone Duo, open',
    size: Size(669, 951),
    padding: EdgeInsets.only(top: 24, bottom: 20),
    state: FoldState(
      isFoldable: true,
      posture: HingePosture.fullyOpen,
      hingeAngle: 180,
      regions: [
        FoldRegion(
          kind: RegionKind.fold,
          bounds: Rect.fromLTRB(334.5, 0, 334.5, 951),
          isActive: false,
        ),
      ],
      horizontalSizeClass: SizeClass.regular,
      verticalSizeClass: SizeClass.regular,
    ),
  );

  static const pixelFoldCover = FoldDevicePreset(
    name: 'Pixel Fold, closed',
    size: Size(412, 869),
    padding: _androidBars,
    state: _closedAndroid,
  );

  static const pixelFoldOpen = FoldDevicePreset(
    name: 'Pixel Fold, open',
    size: Size(841, 701),
    padding: _androidBars,
    state: FoldState(
      isFoldable: true,
      posture: HingePosture.fullyOpen,
      hingeAngle: 180,
      regions: [
        FoldRegion(
          kind: RegionKind.fold,
          bounds: Rect.fromLTRB(420.5, 0, 420.5, 701),
          isActive: false,
        ),
      ],
      horizontalSizeClass: SizeClass.unspecified,
      verticalSizeClass: SizeClass.unspecified,
    ),
  );

  /// Opened, turned upright and half open: the fold runs across.
  static const pixelFoldTabletop = FoldDevicePreset(
    name: 'Pixel Fold, tabletop',
    size: Size(701, 841),
    padding: _androidBars,
    state: FoldState(
      isFoldable: true,
      posture: HingePosture.partiallyOpen,
      hingeAngle: 90,
      regions: [
        FoldRegion(
          kind: RegionKind.fold,
          bounds: Rect.fromLTRB(0, 420.5, 701, 420.5),
          isActive: true,
        ),
      ],
      horizontalSizeClass: SizeClass.unspecified,
      verticalSizeClass: SizeClass.unspecified,
    ),
  );

  /// Galaxy Z Fold5 size; later models' covers are a little wider.
  static const galaxyZFoldCover = FoldDevicePreset(
    name: 'Galaxy Z Fold, closed',
    size: Size(344, 882),
    padding: _androidBars,
    state: _closedAndroid,
  );

  static const galaxyZFoldOpen = FoldDevicePreset(
    name: 'Galaxy Z Fold, open',
    size: Size(690, 829),
    padding: _androidBars,
    state: FoldState(
      isFoldable: true,
      posture: HingePosture.fullyOpen,
      hingeAngle: 180,
      regions: [
        FoldRegion(
          kind: RegionKind.fold,
          bounds: Rect.fromLTRB(345, 0, 345, 829),
          isActive: false,
        ),
      ],
      horizontalSizeClass: SizeClass.unspecified,
      verticalSizeClass: SizeClass.unspecified,
    ),
  );

  /// An app on the outer display of a closed Galaxy Z Flip5 (720 × 748 px at
  /// a density of 1.75). Some Android 14 builds report a density of 3 for
  /// that display, which makes it about 240 × 249 pt.
  static const galaxyZFlipCover = FoldDevicePreset(
    name: 'Galaxy Z Flip, closed',
    size: Size(411, 427),
    padding: EdgeInsets.only(top: 24),
    state: _closedAndroid,
  );

  static const galaxyZFlipOpen = FoldDevicePreset(
    name: 'Galaxy Z Flip, open',
    size: Size(412, 1006),
    padding: _androidBars,
    state: FoldState(
      isFoldable: true,
      posture: HingePosture.fullyOpen,
      hingeAngle: 180,
      regions: [
        FoldRegion(
          kind: RegionKind.fold,
          bounds: Rect.fromLTRB(0, 503, 412, 503),
          isActive: false,
        ),
      ],
      horizontalSizeClass: SizeClass.unspecified,
      verticalSizeClass: SizeClass.unspecified,
    ),
  );

  /// Half open, standing on its lower half (Flex mode).
  static const galaxyZFlipFlex = FoldDevicePreset(
    name: 'Galaxy Z Flip, Flex mode',
    size: Size(412, 1006),
    padding: _androidBars,
    state: FoldState(
      isFoldable: true,
      posture: HingePosture.partiallyOpen,
      hingeAngle: 100,
      regions: [
        FoldRegion(
          kind: RegionKind.fold,
          bounds: Rect.fromLTRB(0, 503, 412, 503),
          isActive: true,
        ),
      ],
      horizontalSizeClass: SizeClass.unspecified,
      verticalSizeClass: SizeClass.unspecified,
    ),
  );

  /// Every preset, for running one test on each:
  ///
  /// ```dart
  /// for (final preset in FoldDevicePreset.all) {
  ///   testWidgets('checkout on ${preset.name}', (tester) async {
  ///     await tester.pumpWidget(FoldPreview(preset: preset, child: const MyApp()));
  ///     ...
  ///   });
  /// }
  /// ```
  static const all = [
    phone,
    tablet,
    iPhoneDuoCover,
    iPhoneDuoOpen,
    pixelFoldCover,
    pixelFoldOpen,
    pixelFoldTabletop,
    galaxyZFoldCover,
    galaxyZFoldOpen,
    galaxyZFlipCover,
    galaxyZFlipOpen,
    galaxyZFlipFlex,
  ];

  static const _closed = FoldState(
    isFoldable: true,
    posture: HingePosture.closed,
    hingeAngle: 0,
    regions: [],
    horizontalSizeClass: SizeClass.compact,
    verticalSizeClass: SizeClass.regular,
  );

  static const _closedAndroid = FoldState(
    isFoldable: true,
    posture: HingePosture.closed,
    hingeAngle: 0,
    regions: [],
    horizontalSizeClass: SizeClass.unspecified,
    verticalSizeClass: SizeClass.unspecified,
  );

  @override
  String toString() => 'FoldDevicePreset($name, $size)';
}

/// Renders [child] as it would look on [preset]: its screen size, safe area
/// and fold state, scaled to fit the space available.
///
/// It stands in for [FoldScope], so [child] is usually the `MaterialApp`.
/// Nothing is asked of the platform and orientations are left alone.
class FoldPreview extends StatefulWidget {
  const FoldPreview({
    super.key,
    required this.preset,
    required this.child,
    this.config = const FoldAdaptiveConfig(),
  });

  final FoldDevicePreset preset;
  final FoldAdaptiveConfig config;
  final Widget child;

  @override
  State<FoldPreview> createState() => _FoldPreviewState();
}

class _FoldPreviewState extends State<FoldPreview> {
  final _rootKey = GlobalKey(debugLabel: 'FoldPreview.screen');

  @override
  Widget build(BuildContext context) {
    final preset = widget.preset;
    final base = MediaQuery.maybeOf(context) ?? const MediaQueryData();
    return FittedBox(
      child: ClipRect(
        child: SizedBox.fromSize(
          key: _rootKey,
          size: preset.size,
          child: FoldCoordinateSpace(
            rootKey: _rootKey,
            child: MediaQuery(
              data: base.copyWith(
                size: preset.size,
                padding: preset.padding,
                viewPadding: preset.padding,
                viewInsets: EdgeInsets.zero,
                displayFeatures: const [],
              ),
              child: FoldMediaQuery(
                state: preset.state,
                formFactor: resolveFormFactor(
                  window: preset.size,
                  fold: preset.state,
                  config: widget.config,
                ),
                config: widget.config,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
