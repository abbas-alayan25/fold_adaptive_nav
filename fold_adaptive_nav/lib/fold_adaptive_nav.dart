/// Foldable-aware navigation for Flutter.
///
/// Wrap the app in a [FoldScope], build tabs with [AdaptiveNavScaffold] and
/// flows with [PinnedActionBody]. Read the result anywhere with
/// `context.formFactor` and [FoldMediaQuery].
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
export 'src/config.dart';
export 'src/flow_widgets.dart';
export 'src/fold_media_query.dart';
export 'src/fold_scope.dart';
export 'src/form_factor.dart';
export 'src/nav_style.dart';
export 'src/orientation_policy.dart';
export 'src/pinned_action_body.dart';
