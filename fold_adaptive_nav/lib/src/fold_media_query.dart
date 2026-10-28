import 'package:flutter/widgets.dart';
import 'package:fold_adaptive_nav_platform_interface/fold_adaptive_nav_platform_interface.dart';

import 'config.dart';
import 'form_factor.dart';

/// The parts of [FoldMediaQuery] a widget can depend on separately.
enum FoldAspect {
  /// [FoldMediaQuery.formFactorOf].
  formFactor,

  /// [FoldMediaQuery.postureOf].
  posture,

  /// [FoldMediaQuery.isFoldableOf].
  isFoldable,

  /// [FoldMediaQuery.regionsOf].
  regions,

  /// [FoldMediaQuery.horizontalSizeClassOf] and
  /// [FoldMediaQuery.verticalSizeClassOf].
  sizeClass,

  /// [FoldMediaQuery.stateOf].
  state,

  /// [FoldMediaQuery.configOf].
  config,
}

/// Publishes the fold state and form factor below a [FoldScope].
///
/// Each `...Of` accessor registers a dependency on one aspect only, so a
/// widget that reads [formFactorOf] doesn't rebuild when the regions move.
class FoldMediaQuery extends InheritedModel<FoldAspect> {
  /// Publishes [state], [formFactor] and [config]. [FoldScope] builds this;
  /// apps read it with the `...Of` methods.
  const FoldMediaQuery({
    super.key,
    required this.state,
    required this.formFactor,
    required this.config,
    required super.child,
  });

  /// The fold state from the platform.
  final FoldState state;

  /// The layout decision.
  final FormFactor formFactor;

  /// The scope's configuration.
  final FoldAdaptiveConfig config;

  static FoldMediaQuery? _of(BuildContext context, FoldAspect aspect) =>
      InheritedModel.inheritFrom<FoldMediaQuery>(context, aspect: aspect);

  /// The form factor. Without a [FoldScope] above, decides from the window
  /// size alone.
  static FormFactor formFactorOf(BuildContext context) {
    final scope = _of(context, FoldAspect.formFactor);
    if (scope != null) return scope.formFactor;
    return resolveFormFactor(
      window: MediaQuery.sizeOf(context),
      fold: FoldState.unsupported,
    );
  }

  /// The hinge posture; [HingePosture.unknown] without a `FoldScope`.
  static HingePosture postureOf(BuildContext context) =>
      _of(context, FoldAspect.posture)?.state.posture ?? HingePosture.unknown;

  /// Whether the device has a hinge.
  static bool isFoldableOf(BuildContext context) =>
      _of(context, FoldAspect.isFoldable)?.state.isFoldable ?? false;

  /// The fold and camera regions, in logical pixels.
  static List<FoldRegion> regionsOf(BuildContext context) =>
      _of(context, FoldAspect.regions)?.state.regions ?? const [];

  /// UIKit's horizontal size class; [SizeClass.unspecified] on Android.
  static SizeClass horizontalSizeClassOf(BuildContext context) =>
      _of(context, FoldAspect.sizeClass)?.state.horizontalSizeClass ??
      SizeClass.unspecified;

  /// UIKit's vertical size class; [SizeClass.unspecified] on Android.
  static SizeClass verticalSizeClassOf(BuildContext context) =>
      _of(context, FoldAspect.sizeClass)?.state.verticalSizeClass ??
      SizeClass.unspecified;

  /// The whole state; rebuilds on any change.
  static FoldState stateOf(BuildContext context) =>
      _of(context, FoldAspect.state)?.state ?? FoldState.unsupported;

  /// The `FoldScope`'s configuration, or the defaults without one.
  static FoldAdaptiveConfig configOf(BuildContext context) =>
      _of(context, FoldAspect.config)?.config ?? const FoldAdaptiveConfig();

  @override
  bool updateShouldNotify(FoldMediaQuery oldWidget) =>
      state != oldWidget.state ||
      formFactor != oldWidget.formFactor ||
      config != oldWidget.config;

  @override
  bool updateShouldNotifyDependent(
    FoldMediaQuery oldWidget,
    Set<FoldAspect> dependencies,
  ) {
    final old = oldWidget.state;
    return dependencies.any((aspect) => switch (aspect) {
          FoldAspect.formFactor => formFactor != oldWidget.formFactor,
          FoldAspect.posture => state.posture != old.posture,
          FoldAspect.isFoldable => state.isFoldable != old.isFoldable,
          FoldAspect.regions => !_listEquals(state.regions, old.regions),
          FoldAspect.sizeClass =>
            state.horizontalSizeClass != old.horizontalSizeClass ||
                state.verticalSizeClass != old.verticalSizeClass,
          FoldAspect.state => state != old,
          FoldAspect.config => config != oldWidget.config,
        });
  }

  static bool _listEquals(List<FoldRegion> a, List<FoldRegion> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// `context.formFactor`, shorthand for [FoldMediaQuery.formFactorOf].
extension FoldContext on BuildContext {
  /// The form factor; see [FoldMediaQuery.formFactorOf].
  FormFactor get formFactor => FoldMediaQuery.formFactorOf(this);
}

/// Pins the form factor of a subtree, for tests and previews.
class FormFactorOverride extends StatelessWidget {
  /// Reports [formFactor] to [child] and everything below it.
  const FormFactorOverride({
    super.key,
    required this.formFactor,
    required this.child,
  });

  /// The form factor to report.
  final FormFactor formFactor;

  /// The subtree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final parent = context.dependOnInheritedWidgetOfExactType<FoldMediaQuery>();
    return FoldMediaQuery(
      state: parent?.state ?? FoldState.unsupported,
      formFactor: formFactor,
      config: parent?.config ?? const FoldAdaptiveConfig(),
      child: child,
    );
  }
}
