import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:fold_adaptive_nav_platform_interface/fold_adaptive_nav_platform_interface.dart';

import 'fold_media_query.dart';
import 'form_factor.dart';

/// Called with the value before and after a change.
typedef FoldChangeCallback<T> = void Function(T previous, T current);

/// Calls back when the device folds, unfolds or the layout changes: to pause
/// a video, save a draft or log the posture.
///
/// The callbacks run after the frame that shows the change, so they may call
/// `setState`. Nothing is called for the first reading.
class FoldListener extends StatefulWidget {
  const FoldListener({
    super.key,
    required this.child,
    this.onPostureChanged,
    this.onFormFactorChanged,
  });

  final Widget child;
  final FoldChangeCallback<HingePosture>? onPostureChanged;
  final FoldChangeCallback<FormFactor>? onFormFactorChanged;

  @override
  State<FoldListener> createState() => _FoldListenerState();
}

class _FoldListenerState extends State<FoldListener> {
  HingePosture? _posture;
  FormFactor? _formFactor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final posture = FoldMediaQuery.postureOf(context);
    final formFactor = context.formFactor;
    final previousPosture = _posture;
    final previousFormFactor = _formFactor;
    _posture = posture;
    _formFactor = formFactor;

    // The platform's first reading turns `unknown` into a posture; that is
    // a start, not a change.
    final postureChanged = previousPosture != null &&
        previousPosture != HingePosture.unknown &&
        previousPosture != posture;
    final formFactorChanged =
        previousFormFactor != null && previousFormFactor != formFactor;
    if (!postureChanged && !formFactorChanged) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (postureChanged) {
        widget.onPostureChanged?.call(previousPosture, posture);
      }
      if (formFactorChanged) {
        widget.onFormFactorChanged?.call(previousFormFactor, formFactor);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
