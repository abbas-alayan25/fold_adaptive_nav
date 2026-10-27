import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'models.dart';

/// The interface that platform implementations of `fold_adaptive_nav` extend.
///
/// The default instance is [UnsupportedFoldPlatform], which answers
/// [FoldState.unsupported]. The iOS and Android packages replace it at
/// startup.
abstract class FoldPlatform extends PlatformInterface {
  FoldPlatform() : super(token: _token);

  static final Object _token = Object();

  static FoldPlatform _instance = UnsupportedFoldPlatform();

  static FoldPlatform get instance => _instance;

  static set instance(FoldPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// The current state. Also answers "is it a foldable".
  ///
  /// Use this, not [changes], to detect support: an event stream swallows
  /// activation failures, so a silent stream can't be told apart from a
  /// missing plugin.
  Future<FoldState> snapshot();

  /// Posture, region and size-class changes.
  Stream<FoldState> get changes;

  /// Raw hinge angle in degrees, at most once per frame.
  ///
  /// Use it for animations; keep it out of the widget tree's rebuilds.
  Stream<double> get hingeAngle;

  /// iOS 27.1+: turns the vertical system bar on the cover display off or
  /// back on. A no-op elsewhere.
  Future<void> setVerticalSystemBarDisabled(bool disabled);
}

/// The fallback for platforms without a native implementation.
class UnsupportedFoldPlatform extends FoldPlatform {
  @override
  Future<FoldState> snapshot() async => FoldState.unsupported;

  @override
  Stream<FoldState> get changes => const Stream.empty();

  @override
  Stream<double> get hingeAngle => const Stream.empty();

  @override
  Future<void> setVerticalSystemBarDisabled(bool disabled) async {}
}
