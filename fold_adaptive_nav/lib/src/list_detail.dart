import 'package:flutter/widgets.dart';

import 'split_view.dart';

/// A list and the item opened from it, side by side where there's room and
/// one at a time where there isn't.
///
/// | Device | Shows |
/// |---|---|
/// | Opened foldable, wide tablet | [list] \| [detail], or [emptyDetail] while nothing is open |
/// | Phone, cover display | [list], or [detail] while one is open |
///
/// The app owns the selection: pass a [detail] while an item is open and
/// null otherwise. On phones, back (the system gesture, or
/// `Navigator.maybePop`) calls [onCloseDetail] instead of leaving the page.
/// Opening an item on the cover and unfolding keeps it open, now beside the
/// list.
///
/// ```dart
/// AdaptiveListDetail(
///   list: MessageList(onOpen: (id) => setState(() => openId = id)),
///   detail: openId == null ? null : MessageDetail(id: openId!),
///   onCloseDetail: () => setState(() => openId = null),
/// )
/// ```
class AdaptiveListDetail extends StatelessWidget {
  /// Shows [list] and the open [detail].
  const AdaptiveListDetail({
    super.key,
    required this.list,
    required this.detail,
    required this.onCloseDetail,
    this.emptyDetail = const SizedBox.shrink(),
    this.mode = FoldSplitMode.hingeOrWide,
    this.listFraction = 0.4,
    this.minPaneExtent = 280,
  });

  /// The list. Its items open with a callback of the app's that sets
  /// [detail].
  final Widget list;

  /// The open item, or null.
  final Widget? detail;

  /// Called when back closes [detail] on a phone.
  final VoidCallback onCloseDetail;

  /// Beside the list while nothing is open, such as "Pick a message".
  final Widget emptyDetail;

  /// When the panes go side by side.
  final FoldSplitMode mode;

  /// The fraction of the width the list takes in a wide window without a
  /// fold. At a fold, the fold decides, unless it would leave a pane
  /// narrower than [minPaneExtent] on a flat device.
  final double listFraction;

  /// The narrowest the list or the detail may get beside each other; see
  /// [FoldSplitView.minPaneExtent].
  final double minPaneExtent;

  @override
  Widget build(BuildContext context) {
    final open = detail != null;
    return FoldSplitView(
      mode: mode,
      wideSplit: listFraction,
      minPaneExtent: minPaneExtent,
      start: list,
      end: detail ?? emptyDetail,
      singleBuilder: (context, list, detail) => PopScope(
        canPop: !open,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && open) onCloseDetail();
        },
        // The list stays in the tree under the detail, so its scroll
        // position is still there when the detail closes.
        child: IndexedStack(
          index: open ? 1 : 0,
          sizing: StackFit.expand,
          children: [list, open ? detail : const SizedBox.shrink()],
        ),
      ),
    );
  }
}
