import 'package:fold_adaptive_nav_platform_interface/fold_adaptive_nav_platform_interface.dart';

/// The ios implementation of `fold_adaptive_nav`.
class FoldAdaptiveNavIos extends MethodChannelFold {
  /// Called by Flutter's plugin registrant at startup.
  static void registerWith() {
    FoldPlatform.instance = FoldAdaptiveNavIos();
  }
}
