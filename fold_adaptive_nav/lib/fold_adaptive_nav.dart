/// Foldable-aware navigation for Flutter.
///
/// Wrap the app in a [FoldScope], build tabs with [AdaptiveNavScaffold] and
/// flows with [PinnedActionBody], and panes with [FoldSplitView]. Read the
/// result anywhere with `context.formFactor` and [FoldMediaQuery].
library;

export 'package:fold_adaptive_nav_platform_interface/fold_adaptive_nav_platform_interface.dart'
    show
        FoldPlatform,
        FoldRegion,
        FoldState,
        HingePosture,
        RegionKind,
        SizeClass;

export 'src/adaptive_nav_scaffold.dart';
export 'src/adaptive_sheet.dart';
export 'src/adaptive_values.dart';
export 'src/config.dart';
export 'src/debug_overlay.dart';
export 'src/device_presets.dart';
export 'src/flow_widgets.dart';
export 'src/fold_geometry.dart' show FoldCoordinateSpace;
export 'src/fold_listener.dart';
export 'src/fold_media_query.dart';
export 'src/fold_safe_area.dart';
export 'src/fold_scope.dart';
export 'src/form_factor.dart';
export 'src/list_detail.dart';
export 'src/nav_style.dart';
export 'src/orientation_policy.dart';
export 'src/pinned_action_body.dart';
export 'src/split_view.dart';
