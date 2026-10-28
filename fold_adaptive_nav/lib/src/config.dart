import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fold_adaptive_nav_platform_interface/fold_adaptive_nav_platform_interface.dart';

import 'form_factor.dart';

/// Decides the form factor in place of [resolveFormFactor]. [suggested] is
/// what the package would pick; return it to keep the default.
typedef FormFactorResolver = FormFactor Function(
  Size window,
  FoldState fold,
  FormFactor suggested,
);

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
    this.tabletBottomBarMaxWidth = double.infinity,
    this.coverMinShortestSide = 0,
    this.compactCoverRailBelow = 400,
    this.treatOpenedFlipsAsPhones = true,
    this.formFactorResolver,
    this.drawerFromWidth,
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

  /// Width cap of the bottom bar on tablets and opened foldables, centred.
  /// Full width by default; 560 keeps the tabs together on wide screens.
  /// `AdaptiveNavStyle.barMaxWidth` wins over it.
  final double tabletBottomBarMaxWidth;

  /// A closed foldable whose display is narrower than this on its shortest
  /// side gets the phone layout instead of the cover layout. 0, the default,
  /// gives every closed foldable the cover layout.
  ///
  /// Narrow covers such as a Galaxy Z Fold's (about 344–373 pt) are shaped
  /// like phones; 380 sends them to the phone layout while the Pixel Fold
  /// (412 pt) and iPhone Duo (466 pt) covers keep the rail.
  final double coverMinShortestSide;

  /// Below this window width the cover rail is compact: narrower
  /// ([AdaptiveNavStyle.compactRailWidth]) and without labels.
  final double compactCoverRailBelow;

  /// An opened foldable in a phone-sized window, with a fold reported in it,
  /// is a flip phone (Galaxy Z Flip, Razr): it follows
  /// [lockPhonesToPortrait] like any phone. Off, it turns freely like any
  /// opened foldable.
  final bool treatOpenedFlipsAsPhones;

  /// Overrides the form factor decision. Use a top-level or static function
  /// so the config stays `const` and compares equal across rebuilds.
  final FormFactorResolver? formFactorResolver;

  /// From this window width, tablets get a permanent [NavigationDrawer]
  /// with labels beside the icons, instead of [tabletNavigation]. Null, the
  /// default, never shows one; Material suggests 1200.
  final double? drawerFromWidth;

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
      other.tabletBottomBarMaxWidth == tabletBottomBarMaxWidth &&
      other.coverMinShortestSide == coverMinShortestSide &&
      other.compactCoverRailBelow == compactCoverRailBelow &&
      other.treatOpenedFlipsAsPhones == treatOpenedFlipsAsPhones &&
      other.formFactorResolver == formFactorResolver &&
      other.drawerFromWidth == drawerFromWidth;

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
        coverMinShortestSide,
        compactCoverRailBelow,
        treatOpenedFlipsAsPhones,
        formFactorResolver,
        drawerFromWidth,
      );
}
