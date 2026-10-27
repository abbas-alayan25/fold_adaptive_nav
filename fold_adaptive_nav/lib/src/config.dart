import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Where the cover display's rail and thumb column go.
enum RailSide {
  /// The physical right edge, under the right thumb, also in RTL locales.
  trailingPhysicalRight,

  /// The physical left edge, for left-handed use.
  physicalLeft,

  /// The trailing edge of the ambient text direction (left in RTL).
  followTextDirection,
}

/// Where along the cover display's rail the tabs sit. Together with
/// [RailSide] this picks the corner: bottom right, top right, and so on.
enum CoverRailAlignment {
  /// At the foot of the rail, under the thumb. The default.
  bottom,

  /// In the middle of the rail.
  center,

  /// At the head of the rail, below the status bar.
  top,
}

/// Tab navigation on tablets and opened foldables.
enum TabletNavigation {
  /// A floating bottom bar, capped in width and centred. The default.
  bottomBar,

  /// A Material [NavigationRail] on the leading edge.
  rail,
}

/// What [FoldScope] writes into `MediaQuery.displayFeatures`.
enum DisplayFeatureBridge {
  /// Nothing. Leaves `MediaQuery` as Flutter made it, so dialogs, sheets and
  /// menus keep the whole inner display.
  none,

  /// Camera and sensor housings, as cutouts.
  cutoutsOnly,

  /// Cutouts, plus the fold while the device is partly open. Flutter's
  /// `DisplayFeatureSubScreen` then keeps dialogs to one half of the display.
  full,
}

/// Everything about [FoldScope]'s behaviour that an app can choose.
@immutable
class FoldAdaptiveConfig {
  const FoldAdaptiveConfig({
    this.coverRailSide = RailSide.trailingPhysicalRight,
    this.coverRailAlignment = CoverRailAlignment.bottom,
    this.tabletNavigation = TabletNavigation.bottomBar,
    this.coverOrientations = const [DeviceOrientation.portraitUp],
    this.lockPhonesToPortrait = true,
    this.manageOrientations = true,
    this.mediumBreakpoint = 600,
    this.expandedBreakpoint = 840,
    this.tabletBottomBarMaxWidth = 560,
  });

  final RailSide coverRailSide;

  /// Where the tabs and the trailing action sit along the cover rail.
  final CoverRailAlignment coverRailAlignment;

  final TabletNavigation tabletNavigation;

  /// Orientations allowed while a foldable is closed.
  final List<DeviceOrientation> coverOrientations;

  /// Keep ordinary phones in portrait.
  final bool lockPhonesToPortrait;

  /// Let [FoldScope] call `SystemChrome.setPreferredOrientations` at all.
  final bool manageOrientations;

  /// Shortest side from which a window counts as a tablet (Material: 600).
  final double mediumBreakpoint;

  /// Width from which tablet flows get a side panel (Material: 840).
  final double expandedBreakpoint;

  /// Width cap of the tablet bottom bar; full width at 1366 pt looks broken.
  final double tabletBottomBarMaxWidth;

  @override
  bool operator ==(Object other) =>
      other is FoldAdaptiveConfig &&
      other.coverRailSide == coverRailSide &&
      other.coverRailAlignment == coverRailAlignment &&
      other.tabletNavigation == tabletNavigation &&
      listEquals(other.coverOrientations, coverOrientations) &&
      other.lockPhonesToPortrait == lockPhonesToPortrait &&
      other.manageOrientations == manageOrientations &&
      other.mediumBreakpoint == mediumBreakpoint &&
      other.expandedBreakpoint == expandedBreakpoint &&
      other.tabletBottomBarMaxWidth == tabletBottomBarMaxWidth;

  @override
  int get hashCode => Object.hash(
        coverRailSide,
        coverRailAlignment,
        tabletNavigation,
        Object.hashAll(coverOrientations),
        lockPhonesToPortrait,
        manageOrientations,
        mediumBreakpoint,
        expandedBreakpoint,
        tabletBottomBarMaxWidth,
      );
}
