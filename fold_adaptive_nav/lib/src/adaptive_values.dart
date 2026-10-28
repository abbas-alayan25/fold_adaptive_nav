import 'package:flutter/widgets.dart';

import 'fold_media_query.dart';
import 'form_factor.dart';

/// Material 3's window size classes, by window width.
enum WindowSizeClass {
  /// Under 600 pt: phones, covers, narrow split windows.
  compact(0),

  /// 600 to 839 pt: tablets in portrait, an opened foldable.
  medium(600),

  /// 840 to 1199 pt: tablets in landscape.
  expanded(840),

  /// 1200 to 1599 pt: large tablets, desktop windows.
  large(1200),

  /// 1600 pt and wider.
  extraLarge(1600);

  const WindowSizeClass(this.minWidth);

  /// The narrowest window width in this class.
  final double minWidth;

  /// The class of a window [width] logical pixels wide.
  static WindowSizeClass fromWidth(double width) =>
      values.lastWhere((c) => width >= c.minWidth, orElse: () => compact);

  /// Whether this class is [other] or wider.
  bool operator >=(WindowSizeClass other) => index >= other.index;

  /// Whether this class is narrower than [other].
  bool operator <(WindowSizeClass other) => index < other.index;
}

/// Shorthands for adapting content, next to `context.formFactor`.
extension AdaptiveContext on BuildContext {
  /// The [WindowSizeClass] of the window width. Rebuilds on size changes.
  WindowSizeClass get windowSizeClass =>
      WindowSizeClass.fromWidth(MediaQuery.sizeOf(this).width);

  /// The value for the current form factor: grid columns, paddings, font
  /// sizes. [cover] and [tablet] fall back to [phone].
  ///
  /// ```dart
  /// final columns = context.adaptive(phone: 2, cover: 3, tablet: 4);
  /// ```
  T adaptive<T>({required T phone, T? cover, T? tablet}) =>
      switch (FoldMediaQuery.formFactorOf(this)) {
        FormFactor.phone => phone,
        FormFactor.cover => cover ?? phone,
        FormFactor.tablet => tablet ?? phone,
      };
}

/// Builds a different widget per form factor. [cover] and [tablet] fall back
/// to [phone].
class AdaptiveBuilder extends StatelessWidget {
  /// Builds [phone], or [cover] or [tablet] where they are given.
  const AdaptiveBuilder({
    super.key,
    required this.phone,
    this.cover,
    this.tablet,
  });

  /// Builds for phones, and for the form factors left null.
  final WidgetBuilder phone;

  /// Builds for the cover display of a closed foldable.
  final WidgetBuilder? cover;

  /// Builds for tablets and opened foldables.
  final WidgetBuilder? tablet;

  @override
  Widget build(BuildContext context) =>
      context.adaptive(phone: phone, cover: cover, tablet: tablet)(context);
}
