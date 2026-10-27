import 'package:flutter/material.dart';

import 'fold_media_query.dart';
import 'form_factor.dart';

/// Shows [builder] as a modal bottom sheet on phones and the cover display,
/// and as a dialog capped at [maxDialogWidth] on tablets and opened
/// foldables, where a sheet across the whole width looks stretched.
///
/// The form factor is read once, when the sheet opens.
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxDialogWidth = 560,
  bool isScrollControlled = false,
  bool isDismissible = true,
  bool useRootNavigator = false,
}) {
  if (FoldMediaQuery.formFactorOf(context) == FormFactor.tablet) {
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      useRootNavigator: useRootNavigator,
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxDialogWidth),
          child: builder(context),
        ),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    useRootNavigator: useRootNavigator,
    showDragHandle: true,
    useSafeArea: true,
  );
}
