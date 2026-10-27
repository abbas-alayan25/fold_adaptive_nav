import 'package:flutter/widgets.dart';
import 'package:fold_adaptive_nav_platform_interface/fold_adaptive_nav_platform_interface.dart';

import 'config.dart';
import 'form_factor.dart';

/// The parts of [FoldMediaQuery] a widget can depend on separately.
enum FoldAspect {
  formFactor,
  posture,
  isFoldable,
  regions,
  sizeClass,
  state,
  config
}

/// Publishes the fold state and form factor below a [FoldScope].
///
/// Each `...Of` accessor registers a dependency on one aspect only, so a
/// widget that reads [formFactorOf] doesn't rebuild when the regions move.
class FoldMediaQuery extends InheritedModel<FoldAspect> {
  const FoldMediaQuery({
    super.key,
    required this.state,
    required this.formFactor,
    required this.config,
    required super.child,
  });

  final FoldState state;
  final FormFactor formFactor;
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

  static HingePosture postureOf(BuildContext context) =>
      _of(context, FoldAspect.posture)?.state.posture ?? HingePosture.unknown;

  static bool isFoldableOf(BuildContext context) =>
      _of(context, FoldAspect.isFoldable)?.state.isFoldable ?? false;

  static List<FoldRegion> regionsOf(BuildContext context) =>
      _of(context, FoldAspect.regions)?.state.regions ?? const [];

  static SizeClass horizontalSizeClassOf(BuildContext context) =>
      _of(context, FoldAspect.sizeClass)?.state.horizontalSizeClass ??
      SizeClass.unspecified;

  static SizeClass verticalSizeClassOf(BuildContext context) =>
      _of(context, FoldAspect.sizeClass)?.state.verticalSizeClass ??
      SizeClass.unspecified;

  /// The whole state; rebuilds on any change.
  static FoldState stateOf(BuildContext context) =>
      _of(context, FoldAspect.state)?.state ?? FoldState.unsupported;

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
  FormFactor get formFactor => FoldMediaQuery.formFactorOf(this);
}

/// Pins the form factor of a subtree, for tests and previews.
class FormFactorOverride extends StatelessWidget {
  const FormFactorOverride({
    super.key,
    required this.formFactor,
    required this.child,
  });

  final FormFactor formFactor;
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
