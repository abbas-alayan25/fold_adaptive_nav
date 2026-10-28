import 'package:flutter/widgets.dart';

import 'config.dart';

/// Lays out [content] and a fixed-width [side] next to each other, with the
/// side on the edge [railSide] names, whatever the text direction.
///
/// The row pins its own direction; both children get the ambient direction
/// back. The side is a fixed-width child, never a stretched one: without a
/// width, a stretched second child takes the max width.
class SideLayout extends StatelessWidget {
  /// Places [side] on the edge [railSide] names, beside [content].
  const SideLayout({
    super.key,
    required this.railSide,
    required this.sideWidth,
    required this.content,
    required this.side,
  });

  /// The edge [side] goes on.
  final RailSide railSide;

  /// The width of [side].
  final double sideWidth;

  /// Takes the rest of the width.
  final Widget content;

  /// The fixed-width side, such as a rail.
  final Widget side;

  @override
  Widget build(BuildContext context) {
    final ambient = Directionality.of(context);
    final sideOnRight = switch (railSide) {
      RailSide.trailingPhysicalRight => true,
      RailSide.physicalLeft => false,
      RailSide.followTextDirection => ambient == TextDirection.ltr,
    };
    final contentChild = Expanded(
      child: MediaQuery.removePadding(
        context: context,
        removeLeft: !sideOnRight,
        removeRight: sideOnRight,
        child: Directionality(textDirection: ambient, child: content),
      ),
    );
    final sideChild = SizedBox(
      width: sideWidth,
      child: MediaQuery.removePadding(
        context: context,
        removeLeft: sideOnRight,
        removeRight: !sideOnRight,
        child: Directionality(textDirection: ambient, child: side),
      ),
    );
    return Row(
      textDirection: TextDirection.ltr,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children:
          sideOnRight ? [contentChild, sideChild] : [sideChild, contentChild],
    );
  }
}
