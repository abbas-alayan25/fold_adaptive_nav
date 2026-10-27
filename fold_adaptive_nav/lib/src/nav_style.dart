import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// When tab labels show.
enum NavLabelBehavior {
  /// Under every icon. The default.
  alwaysShow,

  /// Only under the selected icon.
  onlySelected,

  /// Never; the label is still read out by screen readers.
  alwaysHide,
}

/// How [AdaptiveNavScaffold]'s bars and rails look. Every field is optional;
/// what is left out keeps the Material 3 default.
///
/// Set it for the whole app as a theme extension:
///
/// ```dart
/// ThemeData(extensions: const [AdaptiveNavStyle(indicatorColor: Colors.teal)])
/// ```
///
/// or on one scaffold with [AdaptiveNavScaffold.style], which wins field by
/// field over the theme.
@immutable
class AdaptiveNavStyle extends ThemeExtension<AdaptiveNavStyle> {
  const AdaptiveNavStyle({
    this.backgroundColor,
    this.indicatorColor,
    this.indicatorShape,
    this.selectedColor,
    this.unselectedColor,
    this.selectedLabelStyle,
    this.unselectedLabelStyle,
    this.iconSize,
    this.labelBehavior,
    this.elevation,
    this.shadowColor,
    this.barHeight,
    this.barBorderRadius,
    this.barMargin,
    this.railWidth,
    this.compactRailWidth,
    this.railAlignment,
    this.animationDuration,
  });

  /// Fill of the bar or rail (default: `surfaceContainer`).
  final Color? backgroundColor;

  /// Pill behind the selected icon (default: `secondaryContainer`).
  final Color? indicatorColor;

  /// Shape of that pill (default: a stadium).
  final ShapeBorder? indicatorShape;

  /// Icon and label color of the selected tab.
  final Color? selectedColor;

  /// Icon and label color of the other tabs.
  final Color? unselectedColor;

  /// Merged over `labelMedium` for the selected tab.
  final TextStyle? selectedLabelStyle;

  /// Merged over `labelMedium` for the other tabs.
  final TextStyle? unselectedLabelStyle;

  /// Icon size, also the box custom icons are drawn in (default: 24).
  final double? iconSize;

  final NavLabelBehavior? labelBehavior;

  /// Shadow depth of the floating bottom bar (default: 3).
  final double? elevation;

  final Color? shadowColor;

  /// Height of the bottom bar (default: 68).
  final double? barHeight;

  /// Corners of the bottom bar (default: 32). [BorderRadius.zero] together
  /// with a zero [barMargin] gives a flat, edge-to-edge bar.
  final BorderRadius? barBorderRadius;

  /// Space around the bottom bar, on top of the safe area (default: 12 at
  /// the sides and bottom).
  final EdgeInsets? barMargin;

  /// Width of the cover display's rail (default:
  /// [AdaptiveNavScaffold.railWidth]).
  final double? railWidth;

  /// Width of the compact cover rail, on covers narrower than
  /// `FoldAdaptiveConfig.compactCoverRailBelow` (default:
  /// [AdaptiveNavScaffold.compactRailWidth]). Its labels are hidden.
  final double? compactRailWidth;

  /// Where the cover rail's tabs sit, for alignments
  /// `FoldAdaptiveConfig.coverRailAlignment` doesn't offer (such as
  /// [MainAxisAlignment.spaceEvenly]). Wins over that setting when set.
  final MainAxisAlignment? railAlignment;

  /// Speed of the selection animation (default: 200 ms on the cover rail,
  /// Material's own on the bars).
  final Duration? animationDuration;

  /// The style from the ambient theme, or an empty one.
  static AdaptiveNavStyle of(BuildContext context) =>
      Theme.of(context).extension<AdaptiveNavStyle>() ??
      const AdaptiveNavStyle();

  /// This style with the fields [other] sets taking over.
  AdaptiveNavStyle merge(AdaptiveNavStyle? other) {
    if (other == null) return this;
    return copyWith(
      backgroundColor: other.backgroundColor,
      indicatorColor: other.indicatorColor,
      indicatorShape: other.indicatorShape,
      selectedColor: other.selectedColor,
      unselectedColor: other.unselectedColor,
      selectedLabelStyle: other.selectedLabelStyle,
      unselectedLabelStyle: other.unselectedLabelStyle,
      iconSize: other.iconSize,
      labelBehavior: other.labelBehavior,
      elevation: other.elevation,
      shadowColor: other.shadowColor,
      barHeight: other.barHeight,
      barBorderRadius: other.barBorderRadius,
      barMargin: other.barMargin,
      railWidth: other.railWidth,
      compactRailWidth: other.compactRailWidth,
      railAlignment: other.railAlignment,
      animationDuration: other.animationDuration,
    );
  }

  @override
  AdaptiveNavStyle copyWith({
    Color? backgroundColor,
    Color? indicatorColor,
    ShapeBorder? indicatorShape,
    Color? selectedColor,
    Color? unselectedColor,
    TextStyle? selectedLabelStyle,
    TextStyle? unselectedLabelStyle,
    double? iconSize,
    NavLabelBehavior? labelBehavior,
    double? elevation,
    Color? shadowColor,
    double? barHeight,
    BorderRadius? barBorderRadius,
    EdgeInsets? barMargin,
    double? railWidth,
    double? compactRailWidth,
    MainAxisAlignment? railAlignment,
    Duration? animationDuration,
  }) {
    return AdaptiveNavStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      indicatorColor: indicatorColor ?? this.indicatorColor,
      indicatorShape: indicatorShape ?? this.indicatorShape,
      selectedColor: selectedColor ?? this.selectedColor,
      unselectedColor: unselectedColor ?? this.unselectedColor,
      selectedLabelStyle: selectedLabelStyle ?? this.selectedLabelStyle,
      unselectedLabelStyle: unselectedLabelStyle ?? this.unselectedLabelStyle,
      iconSize: iconSize ?? this.iconSize,
      labelBehavior: labelBehavior ?? this.labelBehavior,
      elevation: elevation ?? this.elevation,
      shadowColor: shadowColor ?? this.shadowColor,
      barHeight: barHeight ?? this.barHeight,
      barBorderRadius: barBorderRadius ?? this.barBorderRadius,
      barMargin: barMargin ?? this.barMargin,
      railWidth: railWidth ?? this.railWidth,
      compactRailWidth: compactRailWidth ?? this.compactRailWidth,
      railAlignment: railAlignment ?? this.railAlignment,
      animationDuration: animationDuration ?? this.animationDuration,
    );
  }

  @override
  AdaptiveNavStyle lerp(AdaptiveNavStyle? other, double t) {
    if (other == null) return this;
    T pick<T>(T a, T b) => t < 0.5 ? a : b;
    return AdaptiveNavStyle(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      indicatorColor: Color.lerp(indicatorColor, other.indicatorColor, t),
      indicatorShape: ShapeBorder.lerp(indicatorShape, other.indicatorShape, t),
      selectedColor: Color.lerp(selectedColor, other.selectedColor, t),
      unselectedColor: Color.lerp(unselectedColor, other.unselectedColor, t),
      selectedLabelStyle:
          TextStyle.lerp(selectedLabelStyle, other.selectedLabelStyle, t),
      unselectedLabelStyle:
          TextStyle.lerp(unselectedLabelStyle, other.unselectedLabelStyle, t),
      iconSize: lerpDouble(iconSize, other.iconSize, t),
      labelBehavior: pick(labelBehavior, other.labelBehavior),
      elevation: lerpDouble(elevation, other.elevation, t),
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t),
      barHeight: lerpDouble(barHeight, other.barHeight, t),
      barBorderRadius:
          BorderRadius.lerp(barBorderRadius, other.barBorderRadius, t),
      barMargin: EdgeInsets.lerp(barMargin, other.barMargin, t),
      railWidth: lerpDouble(railWidth, other.railWidth, t),
      compactRailWidth:
          lerpDouble(compactRailWidth, other.compactRailWidth, t),
      railAlignment: pick(railAlignment, other.railAlignment),
      animationDuration: pick(animationDuration, other.animationDuration),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdaptiveNavStyle &&
      other.backgroundColor == backgroundColor &&
      other.indicatorColor == indicatorColor &&
      other.indicatorShape == indicatorShape &&
      other.selectedColor == selectedColor &&
      other.unselectedColor == unselectedColor &&
      other.selectedLabelStyle == selectedLabelStyle &&
      other.unselectedLabelStyle == unselectedLabelStyle &&
      other.iconSize == iconSize &&
      other.labelBehavior == labelBehavior &&
      other.elevation == elevation &&
      other.shadowColor == shadowColor &&
      other.barHeight == barHeight &&
      other.barBorderRadius == barBorderRadius &&
      other.barMargin == barMargin &&
      other.railWidth == railWidth &&
      other.compactRailWidth == compactRailWidth &&
      other.railAlignment == railAlignment &&
      other.animationDuration == animationDuration;

  @override
  int get hashCode => Object.hash(
        backgroundColor,
        indicatorColor,
        indicatorShape,
        selectedColor,
        unselectedColor,
        selectedLabelStyle,
        unselectedLabelStyle,
        iconSize,
        labelBehavior,
        elevation,
        shadowColor,
        barHeight,
        barBorderRadius,
        barMargin,
        railWidth,
        compactRailWidth,
        railAlignment,
        animationDuration,
      );
}
