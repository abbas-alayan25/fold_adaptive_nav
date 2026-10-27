import 'package:flutter/material.dart';

import 'fold_media_query.dart';
import 'form_factor.dart';
import 'side_layout.dart';

/// Width of the cover display's thumb column: an 84 pt button and a 12 pt
/// gap. At 128 pt it took over a quarter of the 466 pt cover display.
const double kThumbColumnWidth = 96;
const double _thumbColumnGap = 12;

/// Marks a subtree as the cover display's thumb column. Buttons inside
/// switch to their tall layout.
class ThumbColumnScope extends InheritedWidget {
  const ThumbColumnScope({super.key, required super.child});

  /// Whether [context] is inside a thumb column.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThumbColumnScope>() != null;

  @override
  bool updateShouldNotify(ThumbColumnScope oldWidget) => false;
}

/// The primary or secondary action of a flow.
///
/// A wide button with icon and label normally; in a [ThumbColumnScope], a
/// tall one: icon over a label of up to three lines, at least 96 pt high.
class FlowActionButton extends StatelessWidget {
  const FlowActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = true,
  });

  const FlowActionButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : primary = false;

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    if (ThumbColumnScope.of(context)) return _tall(context);
    final iconWidget = icon == null ? null : Icon(icon);
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(64, 52)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
    final text = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    return SizedBox(
      width: double.infinity,
      child: primary
          ? FilledButton.icon(
              onPressed: onPressed, style: style, icon: iconWidget, label: text)
          : OutlinedButton.icon(
              onPressed: onPressed, style: style, icon: iconWidget, label: text),
    );
  }

  Widget _tall(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 96)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.15),
      ),
    );
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 26), const SizedBox(height: 6)],
        Text(
          label,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
    return SizedBox(
      width: double.infinity,
      child: primary
          ? FilledButton(onPressed: onPressed, style: style, child: child)
          : OutlinedButton(onPressed: onPressed, style: style, child: child),
    );
  }
}

/// Buttons side by side; stacked inside a thumb column.
class ActionGroup extends StatelessWidget {
  const ActionGroup({super.key, required this.children, this.spacing = 12});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (ThumbColumnScope.of(context)) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _spaced(children, SizedBox(height: spacing)),
      );
    }
    return Row(
      children: _spaced(
        [for (final c in children) Expanded(child: c)],
        SizedBox(width: spacing),
      ),
    );
  }
}

List<Widget> _spaced(List<Widget> children, Widget gap) => [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) gap,
        children[i],
      ],
    ];

/// "Step 2 of 4" with a row of dots.
class FlowProgress extends StatelessWidget {
  const FlowProgress({
    super.key,
    required this.step,
    required this.stepCount,
    this.labelBuilder,
  }) : assert(step >= 1 && step <= stepCount);

  /// 1-based.
  final int step;
  final int stepCount;

  /// The text above the dots; defaults to "Step [step] of [stepCount]".
  final String Function(int step, int stepCount)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: _label,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_label, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: _dots(context, Axis.horizontal),
          ),
        ],
      ),
    );
  }

  String get _label =>
      labelBuilder?.call(step, stepCount) ?? 'Step $step of $stepCount';

  List<Widget> _dots(BuildContext context, Axis axis) {
    final colors = Theme.of(context).colorScheme;
    return [
      for (var i = 1; i <= stepCount; i++)
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: axis == Axis.horizontal
              ? const EdgeInsetsDirectional.only(end: 6)
              : const EdgeInsets.only(bottom: 6),
          width: axis == Axis.horizontal && i == step ? 20 : 8,
          height: axis == Axis.vertical && i == step ? 20 : 8,
          decoration: BoxDecoration(
            color: i <= step ? colors.primary : colors.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
    ];
  }
}

/// [FlowProgress] for the thumb column: "2/4" over a column of dots.
class FlowProgressColumn extends FlowProgress {
  const FlowProgressColumn({
    super.key,
    required super.step,
    required super.stepCount,
    super.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _label,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$step/$stepCount',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          ..._dots(context, Axis.vertical),
        ],
      ),
    );
  }
}

/// Actions for a screen that isn't a scrolling form: a row under [child]
/// normally, a thumb column on the cover display.
class CoverActionRow extends StatelessWidget {
  const CoverActionRow({
    super.key,
    required this.child,
    required this.actions,
  });

  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    if (context.formFactor == FormFactor.cover) {
      return SideLayout(
        railSide: FoldMediaQuery.configOf(context).coverRailSide,
        sideWidth: kThumbColumnWidth,
        content: child,
        side: ThumbColumn(child: ActionGroup(children: actions)),
      );
    }
    return Column(
      children: [
        Expanded(child: child),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ActionGroup(children: actions),
          ),
        ),
      ],
    );
  }
}

/// The cover display's thumb column: [header] above [child], both as low as
/// possible.
class ThumbColumn extends StatelessWidget {
  const ThumbColumn({super.key, required this.child, this.header});

  final Widget child;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          end: _thumbColumnGap,
          bottom: _thumbColumnGap,
        ),
        child: ThumbColumnScope(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null) ...[
                Center(child: header),
                const SizedBox(height: 16),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}
