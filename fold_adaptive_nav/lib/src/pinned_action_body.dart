import 'package:flutter/material.dart';

import 'config.dart';
import 'flow_widgets.dart';
import 'fold_media_query.dart';
import 'form_factor.dart';
import 'side_layout.dart';

/// The body of one step of a flow, with its primary action where the thumb
/// is:
///
/// | Form factor | Action |
/// |---|---|
/// | phone | pinned to the bottom; content fades out under it |
/// | cover | thumb column on the right, progress dots above, button low |
/// | tablet, narrower than 840 pt | as phone, content kept to 640 pt |
/// | tablet, 840 pt and wider | a 340 pt side panel with progress, footer and action |
class PinnedActionBody extends StatelessWidget {
  const PinnedActionBody({
    super.key,
    required this.child,
    required this.action,
    this.footer,
    this.step,
    this.stepCount,
    this.panelHeader,
  }) : assert((step == null) == (stepCount == null));

  /// The step's content, usually a scroll view.
  final Widget child;

  /// A [FlowActionButton] or an [ActionGroup] of them.
  final Widget action;

  /// Content too wide for the thumb column (a checkbox, a keypad). Sits above
  /// the action normally and moves into the content side on cover.
  final Widget? footer;

  /// 1-based progress; shows [FlowProgress] / [FlowProgressColumn] when set.
  final int? step;
  final int? stepCount;

  /// Shown at the top of the tablet side panel, e.g. a summary.
  final Widget? panelHeader;

  static const double maxContentWidth = 640;
  static const double panelWidth = 340;

  @override
  Widget build(BuildContext context) {
    final formFactor = context.formFactor;
    final config = FoldMediaQuery.configOf(context);
    return LayoutBuilder(
      builder: (context, constraints) => switch (formFactor) {
        FormFactor.cover => _cover(context, config.coverRailSide),
        FormFactor.tablet
            when constraints.maxWidth >= config.expandedBreakpoint =>
          _sidePanel(context),
        FormFactor.tablet => _pinned(context, maxContentWidth: maxContentWidth),
        FormFactor.phone => _pinned(context, maxContentWidth: null),
      },
    );
  }

  bool get _hasProgress => step != null && stepCount != null;

  Widget _constrained(Widget child, double? maxWidth) => maxWidth == null
      ? child
      : Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );

  Widget _pinned(BuildContext context, {required double? maxContentWidth}) {
    final background = Theme.of(context).scaffoldBackgroundColor;
    return Column(
      children: [
        if (_hasProgress)
          _constrained(
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FlowProgress(step: step!, stepCount: stepCount!),
              ),
            ),
            maxContentWidth,
          ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: _constrained(child, maxContentWidth)),
              // Content fades out under the pinned action.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 24,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [background.withValues(alpha: 0), background],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: _constrained(
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (footer != null) ...[footer!, const SizedBox(height: 12)],
                  action,
                ],
              ),
            ),
            maxContentWidth,
          ),
        ),
      ],
    );
  }

  Widget _cover(BuildContext context, RailSide railSide) {
    return SideLayout(
      railSide: railSide,
      sideWidth: kThumbColumnWidth,
      content: Column(
        children: [
          Expanded(child: child),
          if (footer != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: footer,
              ),
            ),
        ],
      ),
      side: ThumbColumn(
        header: _hasProgress
            ? FlowProgressColumn(step: step!, stepCount: stepCount!)
            : null,
        child: action,
      ),
    );
  }

  Widget _sidePanel(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _constrained(child, maxContentWidth)),
        const VerticalDivider(width: 1),
        SizedBox(
          width: panelWidth,
          child: Material(
            color: colors.surfaceContainerLow,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_hasProgress)
                      FlowProgress(step: step!, stepCount: stepCount!),
                    if (panelHeader != null) ...[
                      const SizedBox(height: 24),
                      panelHeader!,
                    ],
                    const Spacer(),
                    if (footer != null) ...[
                      footer!,
                      const SizedBox(height: 16)
                    ],
                    action,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
