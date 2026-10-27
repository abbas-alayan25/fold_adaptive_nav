import 'package:flutter/widgets.dart';
import 'package:fold_adaptive_nav_platform_interface/fold_adaptive_nav_platform_interface.dart';

import 'config.dart';

/// The one layout decision every adaptive widget in this package follows.
enum FormFactor {
  /// An ordinary phone, or a narrow window.
  phone,

  /// The cover display of a closed foldable.
  cover,

  /// A tablet, an opened foldable, or any window at least 600 pt on its
  /// shortest side.
  tablet,
}

/// Decides the [FormFactor] for a window of [window] logical pixels.
///
/// Size comes first, so the answer follows Split View, Stage Manager and
/// freeform windows. The fold state only tells a closed foldable's cover
/// display from a phone of the same size.
FormFactor resolveFormFactor({
  required Size window,
  required FoldState fold,
  FoldAdaptiveConfig config = const FoldAdaptiveConfig(),
}) {
  final shortest = window.shortestSide;
  if (shortest >= config.mediumBreakpoint) return FormFactor.tablet;
  // A cover display is wider than any phone's but much less tall for its
  // width: phones run 1.78 (iPhone SE) to 2.2; the iPhone Duo's cover is 1.46.
  final squat = shortest >= 440 && window.longestSide / shortest < 1.6;
  if (squat || (fold.isFoldable && fold.posture == HingePosture.closed)) {
    return FormFactor.cover;
  }
  return FormFactor.phone;
}
