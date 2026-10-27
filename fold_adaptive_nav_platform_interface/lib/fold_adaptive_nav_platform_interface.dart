/// Platform interface for `fold_adaptive_nav`.
///
/// Platform implementations extend [FoldPlatform] (usually through
/// [MethodChannelFold]) and register themselves as [FoldPlatform.instance].
library;

export 'src/codec.dart';
export 'src/fold_platform.dart';
export 'src/method_channel_fold.dart';
export 'src/models.dart';
