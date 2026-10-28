import 'dart:async';
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fold_adaptive_nav_platform_interface/fold_adaptive_nav_platform_interface.dart';

import 'config.dart';
import 'fold_media_query.dart';
import 'form_factor.dart';
import 'orientation_policy.dart';

/// The one widget an app adds, above its `MaterialApp`.
///
/// It reads the fold state from the platform, publishes it with the form
/// factor through [FoldMediaQuery], and keeps the allowed orientations in
/// line with [orientationsFor].
class FoldScope extends StatefulWidget {
  /// Reads the fold state and publishes it, with the form factor, to [child].
  const FoldScope({
    super.key,
    required this.child,
    this.config = const FoldAdaptiveConfig(),
    this.bridge = DisplayFeatureBridge.none,
    this.debugState,
  });

  /// The app, usually its `MaterialApp`.
  final Widget child;

  /// Layout and orientation choices.
  final FoldAdaptiveConfig config;

  /// What goes into `MediaQuery.displayFeatures` (default: nothing).
  final DisplayFeatureBridge bridge;

  /// Drives the scope from a test instead of the platform. Use
  /// `StreamController(sync: true)`, or each event lands a microtask after
  /// `pump()`.
  final Stream<FoldState>? debugState;

  @override
  State<FoldScope> createState() => _FoldScopeState();
}

class _FoldScopeState extends State<FoldScope> {
  FoldState _state = FoldState.unsupported;
  StreamSubscription<FoldState>? _subscription;

  /// No orientation is set before the first reading: locking portrait early
  /// would pin an opened foldable until the stream catches up.
  bool _hasReading = false;
  List<DeviceOrientation>? _lastOrientations;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(FoldScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.debugState != widget.debugState) {
      _subscription?.cancel();
      _subscribe();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _subscribe() {
    final debugState = widget.debugState;
    if (debugState != null) {
      _subscription = debugState.listen(_onState);
      return;
    }
    // Detect through snapshot(), never the stream: an EventChannel swallows
    // activation failures.
    final platform = FoldPlatform.instance;
    platform.snapshot().then<FoldState>((s) => s, onError: (Object _) {
      return FoldState.unsupported;
    }).then((snapshot) {
      if (!mounted || widget.debugState != null) return;
      _onState(snapshot);
      _subscription = platform.changes.listen(_onState, onError: (_) {});
    });
  }

  void _onState(FoldState state) {
    if (!mounted) return;
    setState(() {
      _hasReading = true;
      _state = state;
    });
  }

  void _applyOrientations(FormFactor formFactor) {
    if (!_hasReading || !widget.config.manageOrientations) return;
    final orientations = orientationsFor(_state, formFactor, widget.config);
    if (listEquals(orientations, _lastOrientations)) return;
    _lastOrientations = orientations;
    SystemChrome.setPreferredOrientations(orientations);
  }

  @override
  Widget build(BuildContext context) {
    final formFactor = resolveFormFactor(
      window: MediaQuery.sizeOf(context),
      fold: _state,
      config: widget.config,
    );
    _applyOrientations(formFactor);

    Widget child = FoldMediaQuery(
      state: _state,
      formFactor: formFactor,
      config: widget.config,
      child: widget.child,
    );
    if (widget.bridge != DisplayFeatureBridge.none) {
      final data = MediaQuery.of(context);
      child = MediaQuery(
        data: data.copyWith(
          displayFeatures: _bridgedFeatures(data.displayFeatures),
        ),
        child: child,
      );
    }
    return child;
  }

  List<DisplayFeature> _bridgedFeatures(List<DisplayFeature> existing) {
    final features = [...existing];
    bool present(Rect bounds) => features.any((f) => f.bounds == bounds);
    for (final region in _state.regions) {
      final bounds = region.bounds;
      if (present(bounds)) continue; // Flutter already published it (Android).
      switch (region.kind) {
        case RegionKind.cameraOcclusion:
          features.add(DisplayFeature(
            bounds: bounds,
            type: DisplayFeatureType.cutout,
            state: DisplayFeatureState.unknown,
          ));
        case RegionKind.fold:
          // Only while partly open, and never a zero-width fold.
          if (widget.bridge == DisplayFeatureBridge.full &&
              _state.posture == HingePosture.partiallyOpen &&
              !bounds.isEmpty) {
            features.add(DisplayFeature(
              bounds: bounds,
              type: DisplayFeatureType.fold,
              state: DisplayFeatureState.postureHalfOpened,
            ));
          }
      }
    }
    return features;
  }
}
