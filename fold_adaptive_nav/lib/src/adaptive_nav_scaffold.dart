import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

import 'adaptive_sheet.dart';
import 'config.dart';
import 'fold_media_query.dart';
import 'form_factor.dart';
import 'nav_style.dart';
import 'side_layout.dart';

/// One tab of an [AdaptiveNavScaffold].
@immutable
class NavDestination {
  const NavDestination({
    required IconData this.icon,
    required this.label,
    this.selectedIcon,
    this.badge,
    this.enabled = true,
  })  : customIcon = null,
        customSelectedIcon = null;

  /// A tab with any widget as its icon, such as an SVG or PNG.
  ///
  /// The icon is laid out in a square box of [AdaptiveNavStyle.iconSize],
  /// under an [IconTheme] carrying the selected or unselected color.
  /// [ImageIcon] picks that color up by itself; for an SVG, read it with
  /// `IconTheme.of(context).color`.
  const NavDestination.custom({
    required Widget icon,
    required this.label,
    Widget? selectedIcon,
    this.badge,
    this.enabled = true,
  })  : icon = null,
        selectedIcon = null,
        customIcon = icon,
        customSelectedIcon = selectedIcon;

  final IconData? icon;
  final IconData? selectedIcon;
  final Widget? customIcon;
  final Widget? customSelectedIcon;
  final String label;

  /// A [Badge] on the icon: `''` shows a dot, any other text a count or
  /// label, `null` nothing.
  final String? badge;

  /// A disabled tab is greyed out and can't be selected.
  final bool enabled;

  /// The icon to draw, in a [size] square so custom images can't stretch
  /// the bar.
  Widget buildIcon({required bool selected, Color? color, double size = 24}) {
    final custom = selected ? customSelectedIcon ?? customIcon : customIcon;
    Widget result;
    if (custom == null) {
      result = Icon(selected ? selectedIcon ?? icon : icon,
          color: color, size: size);
    } else {
      result = IconTheme.merge(
        data: IconThemeData(color: color, size: size),
        child: SizedBox.square(dimension: size, child: custom),
      );
    }
    if (badge != null) {
      result = Badge(
        label: badge!.isEmpty ? null : Text(badge!),
        child: result,
      );
    }
    return result;
  }
}

/// Tabs that move to where the thumb is:
///
/// | Form factor | Renders |
/// |---|---|
/// | phone | [body] + floating bottom bar; [trailingAction] above it |
/// | cover | [body] + a rail on the physical right, action at its foot |
/// | tablet | a bottom bar capped in width, or a [NavigationRail] |
/// | tablet from `FoldAdaptiveConfig.drawerFromWidth` | a [NavigationDrawer] |
///
/// More than [maxBarDestinations] tabs don't fit a bar or the cover rail:
/// the last of its places becomes a "More" tab that lists the rest.
class AdaptiveNavScaffold extends StatefulWidget {
  const AdaptiveNavScaffold({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onSelect,
    required this.body,
    this.trailingAction,
    this.appBar,
    this.style,
    this.backgroundColor,
    this.maxBarDestinations = 5,
    this.moreLabel = 'More',
    this.moreIcon = Icons.more_horiz,
    this.hideBarOnScroll = false,
  })  : assert(destinations.length >= 2),
        assert(maxBarDestinations >= 2);

  final List<NavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final Widget body;

  /// A floating action button on phones and tablets; the foot of the rail on
  /// the cover display.
  final Widget? trailingAction;

  final PreferredSizeWidget? appBar;

  /// Overrides, field by field, the [AdaptiveNavStyle] in the theme.
  final AdaptiveNavStyle? style;

  /// Background of the [Scaffold] in every layout.
  final Color? backgroundColor;

  /// The most tabs the bottom bar and the cover rail show. With more, the
  /// first `maxBarDestinations - 1` show and a [moreLabel] tab opens a list
  /// of the rest. The tablet rail and drawer show every tab.
  final int maxBarDestinations;

  /// Label of the "More" tab; pass a translation.
  final String moreLabel;
  final IconData moreIcon;

  /// Slide the bottom bar away while the body scrolls down, and back while
  /// it scrolls up or at the top. Only the body's outermost vertical
  /// scrollable counts.
  final bool hideBarOnScroll;

  /// Default width of the cover display's rail.
  static const double railWidth = 88;

  /// Default width of the compact cover rail, on narrow covers.
  static const double compactRailWidth = 64;

  /// The bottom of the safe area the home indicator itself takes. A
  /// floating bottom bar may overlap the rest of that area.
  static const double homeIndicatorHeight = 13;

  @override
  State<AdaptiveNavScaffold> createState() => _AdaptiveNavScaffoldState();
}

class _AdaptiveNavScaffoldState extends State<AdaptiveNavScaffold> {
  /// Each layout puts the body somewhere else in the tree. The key moves it
  /// instead of rebuilding it, so scroll positions, form input and stream
  /// subscriptions survive folding and unfolding.
  final _bodyKey = GlobalKey(debugLabel: 'AdaptiveNavScaffold.body');

  List<NavDestination> get destinations => widget.destinations;
  int get currentIndex => widget.currentIndex;
  ValueChanged<int> get onSelect => widget.onSelect;
  Widget? get trailingAction => widget.trailingAction;
  PreferredSizeWidget? get appBar => widget.appBar;
  Widget get body => NotificationListener<UserScrollNotification>(
        onNotification: _onUserScroll,
        child: KeyedSubtree(key: _bodyKey, child: widget.body),
      );

  bool _barVisible = true;

  @override
  void didUpdateWidget(AdaptiveNavScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new tab starts with the bar in view.
    if (oldWidget.currentIndex != currentIndex || !widget.hideBarOnScroll) {
      _barVisible = true;
    }
  }

  bool _onUserScroll(UserScrollNotification notification) {
    if (!widget.hideBarOnScroll ||
        notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical) {
      return false;
    }
    // The direction is reported before the position moves, so "at the top"
    // only counts once scrolling stops.
    final metrics = notification.metrics;
    final visible = switch (notification.direction) {
      ScrollDirection.reverse => false,
      ScrollDirection.forward => true,
      ScrollDirection.idle =>
        metrics.pixels <= metrics.minScrollExtent || _barVisible,
    };
    if (visible != _barVisible) setState(() => _barVisible = visible);
    return false;
  }

  /// The tabs the bottom bar and the cover rail show: all of them, or the
  /// first ones and "More".
  bool get _overflows => destinations.length > widget.maxBarDestinations;
  int get _shownCount =>
      _overflows ? widget.maxBarDestinations - 1 : destinations.length;

  List<NavDestination> get _barDestinations {
    if (!_overflows) return destinations;
    final hidden = destinations.skip(_shownCount);
    return [
      ...destinations.take(_shownCount),
      NavDestination(
        icon: widget.moreIcon,
        label: widget.moreLabel,
        // A dot when a tab behind it has a badge.
        badge: hidden.any((d) => d.badge != null) ? '' : null,
      ),
    ];
  }

  int get _barIndex => math.min(currentIndex, _shownCount);

  void _onBarSelect(int index) {
    if (_overflows && index == _shownCount) {
      _showMore();
    } else {
      onSelect(index);
    }
  }

  void _showMore() {
    showAdaptiveSheet<void>(
      context: context,
      builder: (sheetContext) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          for (var i = _shownCount; i < destinations.length; i++)
            ListTile(
              leading: destinations[i].buildIcon(selected: i == currentIndex),
              title: Text(destinations[i].label),
              selected: i == currentIndex,
              enabled: destinations[i].enabled,
              onTap: () {
                Navigator.pop(sheetContext);
                onSelect(i);
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = FoldMediaQuery.configOf(context);
    final style = AdaptiveNavStyle.of(context).merge(widget.style);
    final drawerFrom = config.drawerFromWidth;
    return switch (context.formFactor) {
      FormFactor.phone =>
        _bottomBarScaffold(context, style, maxBarWidth: style.barMaxWidth),
      FormFactor.cover => _coverScaffold(context, style, config),
      FormFactor.tablet
          when drawerFrom != null &&
              MediaQuery.sizeOf(context).width >= drawerFrom =>
        _drawerScaffold(context, style),
      FormFactor.tablet => config.tabletNavigation == TabletNavigation.rail
          ? _railScaffold(context, style)
          : _bottomBarScaffold(
              context,
              style,
              maxBarWidth: style.barMaxWidth ?? config.tabletBottomBarMaxWidth,
            ),
    };
  }

  Widget _bottomBarScaffold(
    BuildContext context,
    AdaptiveNavStyle style, {
    double? maxBarWidth,
  }) {
    Widget bar = _FloatingNavBar(
      destinations: _barDestinations,
      currentIndex: _barIndex,
      onSelect: _onBarSelect,
      style: style,
      maxWidth: maxBarWidth,
    );
    // Slid by its own height, the bar and the gap below it leave the screen.
    bar = AnimatedSlide(
      offset: _barVisible ? Offset.zero : const Offset(0, 1),
      duration: _motion(context, const Duration(milliseconds: 200)),
      curve: Curves.easeOutCubic,
      child: bar,
    );
    return Scaffold(
      appBar: appBar,
      backgroundColor: widget.backgroundColor,
      extendBody: true,
      body: body,
      floatingActionButton: trailingAction,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: bar,
    );
  }

  Widget _coverScaffold(
    BuildContext context,
    AdaptiveNavStyle style,
    FoldAdaptiveConfig config,
  ) {
    final compact =
        MediaQuery.sizeOf(context).width < config.compactCoverRailBelow;
    // A compact rail has no room for labels; screen readers still get them.
    final railStyle = compact
        ? style.merge(const AdaptiveNavStyle(
            labelBehavior: NavLabelBehavior.alwaysHide,
          ))
        : style;
    return Scaffold(
      appBar: appBar,
      backgroundColor: widget.backgroundColor,
      body: SideLayout(
        railSide: config.coverRailSide,
        sideWidth: compact
            ? style.compactRailWidth ?? AdaptiveNavScaffold.compactRailWidth
            : style.railWidth ?? AdaptiveNavScaffold.railWidth,
        content: body,
        side: SideRail(
          destinations: _barDestinations,
          currentIndex: _barIndex,
          onSelect: _onBarSelect,
          trailingAction: trailingAction,
          style: railStyle,
        ),
      ),
    );
  }

  Widget _drawerScaffold(BuildContext context, AdaptiveNavStyle style) {
    final colors = _NavColors(context, style);
    final iconSize = style.iconSize ?? 24;
    return Scaffold(
      appBar: appBar,
      backgroundColor: widget.backgroundColor,
      body: Row(
        children: [
          NavigationDrawerTheme(
            data: NavigationDrawerTheme.of(context).copyWith(
              iconTheme: WidgetStateProperty.resolveWith(
                (states) => IconThemeData(
                  size: iconSize,
                  color: colors.resolve(states),
                ),
              ),
              labelTextStyle: WidgetStateProperty.resolveWith(
                (states) => colors.label(
                  selected: states.contains(WidgetState.selected),
                  disabled: states.contains(WidgetState.disabled),
                ),
              ),
            ),
            child: NavigationDrawer(
              selectedIndex: currentIndex,
              onDestinationSelected: onSelect,
              backgroundColor: style.backgroundColor,
              indicatorColor: style.indicatorColor,
              indicatorShape: style.indicatorShape,
              elevation: 0,
              children: [
                const SizedBox(height: 12),
                if (trailingAction != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: trailingAction,
                    ),
                  ),
                for (final d in destinations)
                  NavigationDrawerDestination(
                    icon: d.buildIcon(selected: false, size: iconSize),
                    selectedIcon: d.buildIcon(selected: true, size: iconSize),
                    label: Text(d.label),
                    enabled: d.enabled,
                  ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _railScaffold(BuildContext context, AdaptiveNavStyle style) {
    final colors = _NavColors(context, style);
    final iconSize = style.iconSize ?? 24;
    return Scaffold(
      appBar: appBar,
      backgroundColor: widget.backgroundColor,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onSelect,
            labelType: switch (style.labelBehavior) {
              NavLabelBehavior.onlySelected => NavigationRailLabelType.selected,
              NavLabelBehavior.alwaysHide => NavigationRailLabelType.none,
              _ => NavigationRailLabelType.all,
            },
            backgroundColor: style.backgroundColor,
            indicatorColor: style.indicatorColor,
            indicatorShape: style.indicatorShape,
            selectedIconTheme:
                IconThemeData(color: colors.selected, size: iconSize),
            unselectedIconTheme:
                IconThemeData(color: colors.unselected, size: iconSize),
            selectedLabelTextStyle: colors.label(selected: true),
            unselectedLabelTextStyle: colors.label(selected: false),
            leading: trailingAction,
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: d.buildIcon(selected: false, size: iconSize),
                  selectedIcon: d.buildIcon(selected: true, size: iconSize),
                  label: Text(d.label),
                  disabled: !d.enabled,
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.destinations,
    required this.currentIndex,
    required this.onSelect,
    required this.style,
    this.maxWidth,
  });

  final List<NavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final AdaptiveNavStyle style;

  /// Width cap, centred. A floating bar shrinks as a whole; a flat bar keeps
  /// its background edge to edge and caps only its tabs.
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = _NavColors(context, style);
    final iconSize = style.iconSize ?? 24;
    final margin = style.barMargin ?? const EdgeInsets.fromLTRB(12, 0, 12, 12);
    final inset = MediaQuery.paddingOf(context).bottom;
    // A flat bar (no bottom margin) fills the home indicator's area and keeps
    // its tabs above it. A floating bar overlaps the empty part of that area,
    // so it doesn't leave a strip of blank screen under it.
    final flat = margin.bottom == 0;
    final gapBelow = flat
        ? 0.0
        : math.max(
            margin.bottom, inset - AdaptiveNavScaffold.homeIndicatorHeight);
    final bar = SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          margin.left,
          margin.top,
          margin.right,
          gapBelow,
        ),
        child: Material(
          color: style.backgroundColor ?? scheme.surfaceContainer,
          elevation: style.elevation ?? 3,
          shadowColor: style.shadowColor ?? scheme.shadow,
          borderRadius: style.barBorderRadius ?? BorderRadius.circular(32),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.only(bottom: flat ? inset : 0),
            // The padding above handles the safe area; don't pad it twice.
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: NavigationBarTheme(
                data: NavigationBarTheme.of(context).copyWith(
                  iconTheme: WidgetStateProperty.resolveWith(
                    (states) => IconThemeData(
                      size: iconSize,
                      color: colors.resolve(states),
                    ),
                  ),
                  labelTextStyle: WidgetStateProperty.resolveWith(
                    (states) => colors.label(
                      selected: states.contains(WidgetState.selected),
                      disabled: states.contains(WidgetState.disabled),
                    ),
                  ),
                ),
                child: _capWidth(
                  flat ? maxWidth : null,
                  NavigationBar(
                    height: style.barHeight ?? 68,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    indicatorColor: style.indicatorColor,
                    indicatorShape: style.indicatorShape,
                    animationDuration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : style.animationDuration,
                    labelBehavior: switch (style.labelBehavior) {
                      NavLabelBehavior.onlySelected =>
                        NavigationDestinationLabelBehavior.onlyShowSelected,
                      NavLabelBehavior.alwaysHide =>
                        NavigationDestinationLabelBehavior.alwaysHide,
                      _ => NavigationDestinationLabelBehavior.alwaysShow,
                    },
                    selectedIndex: currentIndex,
                    onDestinationSelected: onSelect,
                    destinations: [
                      for (final d in destinations)
                        NavigationDestination(
                          icon: d.buildIcon(selected: false, size: iconSize),
                          selectedIcon:
                              d.buildIcon(selected: true, size: iconSize),
                          label: d.label,
                          enabled: d.enabled,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return flat ? bar : _capWidth(maxWidth, bar);
  }
}

/// [child] centred and at most [maxWidth] wide; unchanged without a finite cap.
Widget _capWidth(double? maxWidth, Widget child) {
  if (maxWidth == null || maxWidth == double.infinity) return child;
  return Align(
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// Icon and label colors for one [AdaptiveNavStyle], with the Material 3
/// navigation defaults where the style leaves them out.
class _NavColors {
  _NavColors(BuildContext context, AdaptiveNavStyle style)
      : _style = style,
        _scheme = Theme.of(context).colorScheme,
        _labelBase =
            Theme.of(context).textTheme.labelMedium ?? const TextStyle();

  final AdaptiveNavStyle _style;
  final ColorScheme _scheme;
  final TextStyle _labelBase;

  Color get selected => _style.selectedColor ?? _scheme.onSecondaryContainer;
  Color get unselected => _style.unselectedColor ?? _scheme.onSurfaceVariant;
  Color get disabled => unselected.withValues(alpha: 0.38);

  Color resolve(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) return disabled;
    return states.contains(WidgetState.selected) ? selected : unselected;
  }

  /// [boldSelected] is for the cover rail, whose labels are its only cue
  /// besides the pill.
  TextStyle label({
    required bool selected,
    bool disabled = false,
    bool boldSelected = false,
  }) {
    final color = disabled
        ? this.disabled
        : selected
            ? _style.selectedColor ?? _scheme.onSurface
            : unselected;
    return _labelBase
        .copyWith(
          color: color,
          fontWeight: selected && boldSelected ? FontWeight.w600 : null,
        )
        .merge(
            selected ? _style.selectedLabelStyle : _style.unselectedLabelStyle);
  }
}

/// The cover display's rail: tabs low on the edge, under the thumb, with the
/// trailing action at its foot.
class SideRail extends StatelessWidget {
  const SideRail({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onSelect,
    this.trailingAction,
    this.style = const AdaptiveNavStyle(),
    this.alignment,
  });

  final List<NavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final Widget? trailingAction;
  final AdaptiveNavStyle style;

  /// Where the tabs sit along the rail (default:
  /// [FoldAdaptiveConfig.coverRailAlignment] from the `FoldScope`).
  final CoverRailAlignment? alignment;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final railAlignment = style.railAlignment ??
        switch (
            alignment ?? FoldMediaQuery.configOf(context).coverRailAlignment) {
          CoverRailAlignment.top => MainAxisAlignment.start,
          CoverRailAlignment.center => MainAxisAlignment.center,
          CoverRailAlignment.bottom => MainAxisAlignment.end,
        };
    return Material(
      color: style.backgroundColor ?? scheme.surfaceContainer,
      child: SafeArea(
        // Scrolls when large text or many tabs don't fit; otherwise the
        // column fills the rail and the alignment applies.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                // Unbounded when a SideRail is used on its own in a column.
                minHeight:
                    constraints.hasBoundedHeight ? constraints.maxHeight : 0,
              ),
              child: _column(railAlignment),
            ),
          ),
        ),
      ),
    );
  }

  Widget _column(MainAxisAlignment railAlignment) {
    return Column(
      mainAxisAlignment: railAlignment,
      children: [
        if (railAlignment != MainAxisAlignment.end) const SizedBox(height: 8),
        for (var i = 0; i < destinations.length; i++)
          _RailItem(
            destination: destinations[i],
            selected: i == currentIndex,
            onTap: () => onSelect(i),
            style: style,
          ),
        if (trailingAction != null) ...[
          const SizedBox(height: 16),
          trailingAction!,
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    required this.style,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final AdaptiveNavStyle style;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = _NavColors(context, style);
    final enabled = destination.enabled;
    final iconSize = style.iconSize ?? 24;
    final showLabel = switch (style.labelBehavior) {
      NavLabelBehavior.alwaysHide => false,
      NavLabelBehavior.onlySelected => selected,
      _ => true,
    };
    return Semantics(
      selected: selected,
      button: true,
      enabled: enabled,
      label: destination.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: enabled ? onTap : null,
        // At least the 48 pt touch target, whatever the icon size.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: _motion(
                    context,
                    style.animationDuration ??
                        const Duration(milliseconds: 200),
                  ),
                  width: 56,
                  height: iconSize + 8,
                  decoration: ShapeDecoration(
                    color: selected
                        ? style.indicatorColor ?? scheme.secondaryContainer
                        : Colors.transparent,
                    shape: style.indicatorShape ?? const StadiumBorder(),
                  ),
                  alignment: Alignment.center,
                  child: destination.buildIcon(
                    selected: selected,
                    color: enabled
                        ? (selected ? colors.selected : colors.unselected)
                        : colors.disabled,
                    size: iconSize,
                  ),
                ),
                if (showLabel) ...[
                  const SizedBox(height: 4),
                  // Large text wraps onto a second line; the rail scrolls
                  // if the tabs no longer fit.
                  Text(
                    destination.label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: colors.label(
                      selected: selected,
                      disabled: !enabled,
                      boldSelected: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [duration], or none when the platform asks for reduced motion.
Duration _motion(BuildContext context, Duration duration) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
