import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'codec.dart';
import 'fold_platform.dart';
import 'models.dart';

/// A [FoldPlatform] that talks to native code over the
/// `fold_adaptive_nav/*` channels. The iOS and Android packages share it.
class MethodChannelFold extends FoldPlatform {
  /// Snapshots and the vertical system bar.
  @visibleForTesting
  static const methods = MethodChannel('fold_adaptive_nav/methods');

  /// Posture, region and size-class changes.
  @visibleForTesting
  static const stateEvents = EventChannel('fold_adaptive_nav/state');

  /// The hinge angle, at most once per frame.
  @visibleForTesting
  static const angleEvents = EventChannel('fold_adaptive_nav/angle');

  Stream<FoldState>? _changes;
  Stream<double>? _hingeAngle;
  FoldState? _lastState;
  double? _lastAngle;

  @override
  Future<FoldState> snapshot() async {
    try {
      return FoldStateCodec.decode(
        await methods.invokeMethod<Object?>('snapshot'),
      );
    } on MissingPluginException {
      return FoldState.unsupported;
    }
  }

  @override
  Stream<FoldState> get changes => _changes ??= _replayingLatest(
        stateEvents.receiveBroadcastStream().map(FoldStateCodec.decode),
        () => _lastState,
        (s) => _lastState = s,
      ).distinct();

  @override
  Stream<double> get hingeAngle => _hingeAngle ??= _replayingLatest(
        angleEvents
            .receiveBroadcastStream()
            .where((event) => event is num)
            .map((event) => (event as num).toDouble()),
        () => _lastAngle,
        (a) => _lastAngle = a,
      );

  /// A broadcast stream that gives each new listener the latest value first.
  ///
  /// The native side sends the current value only when the first listener
  /// arrives; a widget that subscribes later (for example after a layout
  /// switch on fold) would otherwise wait for the next change.
  static Stream<T> _replayingLatest<T extends Object>(
    Stream<T> source,
    T? Function() latest,
    void Function(T) remember,
  ) {
    final shared = source.map((value) {
      remember(value);
      return value;
    }).asBroadcastStream(onCancel: (s) => s.cancel());
    return Stream<T>.multi((controller) {
      final current = latest();
      if (current != null) controller.add(current);
      final subscription = shared.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = subscription.cancel;
    }, isBroadcast: true);
  }

  @override
  Future<void> setVerticalSystemBarDisabled(bool disabled) async {
    try {
      await methods.invokeMethod<void>(
        'setVerticalSystemBarDisabled',
        {'disabled': disabled},
      );
    } on MissingPluginException {
      // Not running on a platform with a native side.
    }
  }
}
