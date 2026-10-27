import 'package:flutter/services.dart';
import 'package:fold_adaptive_nav_platform_interface/fold_adaptive_nav_platform_interface.dart';

import 'config.dart';
import 'form_factor.dart';

/// The orientations an app should allow for [fold] and [formFactor].
///
/// Foldables follow their posture: the cover display uses
/// [FoldAdaptiveConfig.coverOrientations], an opened foldable turns freely.
/// Everything else follows the window: tablets turn freely, phones stay in
/// portrait unless [FoldAdaptiveConfig.lockPhonesToPortrait] is off.
List<DeviceOrientation> orientationsFor(
  FoldState fold,
  FormFactor formFactor,
  FoldAdaptiveConfig config,
) {
  if (fold.isFoldable) {
    switch (fold.posture) {
      case HingePosture.closed:
        return config.coverOrientations;
      case HingePosture.partiallyOpen:
      case HingePosture.fullyOpen:
        return DeviceOrientation.values;
      case HingePosture.unknown:
        break; // No reading yet: use the window.
    }
  }
  return switch (formFactor) {
    FormFactor.tablet => DeviceOrientation.values,
    _ => config.lockPhonesToPortrait
        ? const [DeviceOrientation.portraitUp]
        : DeviceOrientation.values,
  };
}
