import 'dart:math' as math;

import 'package:flutter/cupertino.dart'
    show
        CupertinoColors,
        CupertinoDynamicColor,
        CupertinoTabBar,
        CupertinoTheme;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart'
    show HardwareKeyboard, KeyDownEvent, KeyEvent, LogicalKeyboardKey;

import 'adaptive_sheet.dart';
import 'config.dart';
import 'fold_media_query.dart';
import 'form_factor.dart';
import 'nav_strings.dart';
import 'nav_style.dart';
import 'side_layout.dart';

/// One tab of an [AdaptiveNavScaffold].
@immutable
class NavDestination {
  /// A tab with a Material [icon], and [selectedIcon] while it is the current tab.
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

  /// The icon, or null for a [NavDestination.custom] tab.
  final IconData? icon;

  /// The icon while this is the current tab (default: [icon]).
  final IconData? selectedIcon;

  /// The widget icon of a [NavDestination.custom] tab.
  final Widget? customIcon;

  /// [customIcon] while this is the current tab.
  final Widget? customSelectedIcon;

  /// The tab's name, shown with its icon and read out by screen readers.
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

/// Some tabs under one heading, for [AdaptiveNavScaffold.grouped].
///
/// On side bars a group is a button that opens to show its tabs, and closes
/// the group that was open. Bottom bars show every tab, without headings.
@immutable
class NavGroup {
  /// A group with a Material [icon], and [selectedIcon] while it holds the current tab.
  const NavGroup({
    required IconData this.icon,
    required this.label,
    required this.destinations,
    this.selectedIcon,
  }) : customIcon = null;

  /// A group with any widget as its icon, as [NavDestination.custom].
  const NavGroup.custom({
    required Widget icon,
    required this.label,
    required this.destinations,
  })  : icon = null,
        selectedIcon = null,
        customIcon = icon;

  /// The group's icon, or null for a [NavGroup.custom] group.
  final IconData? icon;

  /// The icon while the current tab is in this group.
  final IconData? selectedIcon;

  /// The widget icon of a [NavGroup.custom] group.
  final Widget? customIcon;

  /// The group's name: on its button, and as its heading in the drawer.
  final String label;

  /// The group's tabs, in order; at least one.
  final List<NavDestination> destinations;

  /// The group's button, drawn like a tab. [badge] is `''` (a dot) when a
  /// tab in it has a badge.
  NavDestination header({String? badge}) {
    final custom = customIcon;
    return custom == null
        ? NavDestination(
            icon: icon!,
            selectedIcon: selectedIcon,
            label: label,
            badge: badge,
          )
        : NavDestination.custom(icon: custom, label: label, badge: badge);
  }
}

/// Tabs that move to where the thumb is:
///
/// | Form factor | Renders |
/// |---|---|
/// | phone | [body] + floating bottom bar; [trailingAction] above it |
/// | cover | [body] + a rail on the physical right, action at its foot |
/// | tablet | a bottom bar, or a side bar (`FoldAdaptiveConfig.tabletNavigation`) |
/// | tablet from `FoldAdaptiveConfig.drawerFromWidth` | a [NavigationDrawer] |
///
/// More than [maxBarDestinations] tabs don't fit a bar or the cover rail:
/// the last of its places becomes a "More" tab that lists the rest.
///
/// [AdaptiveNavScaffold.grouped] puts the tabs under [NavGroup]s, which the
/// side bars and the cover rail show as an accordion.
class AdaptiveNavScaffold extends StatefulWidget {
  /// Tabs from a flat list of at least two [destinations].
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
    this.moreLabel,
    this.moreIcon = Icons.more_horiz,
    this.hideBarOnScroll = false,
    this.restorationId,
    this.keyboardShortcuts = true,
  })  : groups = null,
        assert(destinations.length >= 2),
        assert(maxBarDestinations >= 2);

  /// Tabs under [groups]. [currentIndex] and [onSelect] count the tabs of
  /// all groups in order, as if they were one list: with groups of 3 and 2
  /// tabs, the second group's first tab is 3.
  ///
  /// The cover rail and the tablet side bar (when
  /// `FoldAdaptiveConfig.tabletNavigation` shows one) open one group at a
  /// time. The group holding the current tab opens by itself. Bottom bars
  /// and the drawer list every tab.
  AdaptiveNavScaffold.grouped({
    super.key,
    required List<NavGroup> this.groups,
    required this.currentIndex,
    required this.onSelect,
    required this.body,
    this.trailingAction,
    this.appBar,
    this.style,
    this.backgroundColor,
    this.maxBarDestinations = 5,
    this.moreLabel,
    this.moreIcon = Icons.more_horiz,
    this.hideBarOnScroll = false,
    this.restorationId,
    this.keyboardShortcuts = true,
  })  : destinations = [for (final g in groups) ...g.destinations],
        assert(groups.isNotEmpty),
        assert(groups.every((g) => g.destinations.isNotEmpty)),
        assert(maxBarDestinations >= 2);

  /// Every tab, in order; the groups' tabs one after the other with
  /// [AdaptiveNavScaffold.grouped].
  final List<NavDestination> destinations;

  /// The tab groups, or null for a flat list of tabs.
  final List<NavGroup>? groups;

  /// The selected tab, as an index into [destinations].
  final int currentIndex;

  /// Called with the index of the tab the user picks; update [currentIndex]
  /// from it.
  final ValueChanged<int> onSelect;

  /// The current tab's page. It keeps its state when the layout changes.
  final Widget body;

  /// A floating action button on phones and tablets; the foot of the rail on
  /// the cover display.
  final Widget? trailingAction;

  /// An app bar above [body], in every layout.
  final PreferredSizeWidget? appBar;

  /// Overrides, field by field, the [AdaptiveNavStyle] in the theme.
  final AdaptiveNavStyle? style;

  /// Background of the [Scaffold] in every layout.
  final Color? backgroundColor;

  /// The most tabs the bottom bar and the cover rail show. With more, the
  /// first `maxBarDestinations - 1` show and a [moreLabel] tab opens a list
  /// of the rest. The tablet rail and drawer show every tab.
  final int maxBarDestinations;

  /// Label of the "More" tab.
  ///
  /// Null, the default, uses [NavStrings.more]: "More" in the app's language.
  final String? moreLabel;

  /// The icon of the "More" tab.
  final IconData moreIcon;

  /// Slide the bottom bar away while the body scrolls down, and back while
  /// it scrolls up or at the top. Only the body's outermost vertical
  /// scrollable counts.
  final bool hideBarOnScroll;

  /// Restores the open tab group and the expanded side bar's state after
  /// the system ends the app in the background, as other restorable
  /// widgets do. Needs `MaterialApp.restorationScopeId`. The tab itself is
  /// the app's: restore [currentIndex] with a `RestorableInt` of its own.
  final String? restorationId;

  /// Ctrl+1 to Ctrl+9 (⌘ on Apple keyboards) pick the first nine tabs, on a
  /// tablet or phone with a hardware keyboard.
  final bool keyboardShortcuts;

  /// Default width of the cover display's rail.
  static const double railWidth = 88;

  /// Default width of the compact cover rail, on narrow covers.
  static const double compactRailWidth = 64;

  /// Default width of the expanded tablet side bar.
  static const double expandedRailWidth = 240;

  /// The bottom of the safe area the home indicator itself takes. A
  /// floating bottom bar may overlap the rest of that area.
  static const double homeIndicatorHeight = 13;

  @override
  State<AdaptiveNavScaffold> createState() => _AdaptiveNavScaffoldState();
}

class _AdaptiveNavScaffoldState extends State<AdaptiveNavScaffold>
    with RestorationMixin {
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

  /// The open tab group, shared by the cover rail and the tablet side bar so
  /// it stays open across folding. At first, the group of the current tab.
  late final _openGroup = RestorableIntN(_groupOf(currentIndex));

  /// Whether the expanded side bar is expanded; null until the user picks,
  /// which leaves it to `FoldAdaptiveConfig.expandedRailStartsCollapsed`.
  final _railExpanded = RestorableBoolN(null);

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_openGroup, 'open_group');
    registerForRestoration(_railExpanded, 'rail_expanded');
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _openGroup.dispose();
    _railExpanded.dispose();
    super.dispose();
  }

  List<NavGroup>? get groups => widget.groups;

  /// The group holding tab [index].
  int? _groupOf(int index) {
    final groups = this.groups;
    if (groups == null) return null;
    var start = 0;
    for (var g = 0; g < groups.length; g++) {
      start += groups[g].destinations.length;
      if (index < start) return g;
    }
    return null;
  }

  @override
  void didUpdateWidget(AdaptiveNavScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new tab starts with the bar in view.
    if (oldWidget.currentIndex != currentIndex || !widget.hideBarOnScroll) {
      _barVisible = true;
    }
    // A tab picked from elsewhere opens its group.
    if (oldWidget.currentIndex != currentIndex ||
        (oldWidget.groups == null) != (groups == null)) {
      _openGroup.value = _groupOf(currentIndex) ?? _openGroup.value;
    }
    if (groups == null) _openGroup.value = null;
  }

  /// Opens group [g] and closes the others, or closes it if it was open.
  void _toggleGroup(int g) =>
      setState(() => _openGroup.value = _openGroup.value == g ? null : g);

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
        label: widget.moreLabel ?? NavStrings.more(context),
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

  static const _digits = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
    LogicalKeyboardKey.digit7,
    LogicalKeyboardKey.digit8,
    LogicalKeyboardKey.digit9,
  ];

  // Listens to the keyboard itself rather than through a Focus: a Focus
  // would need focus first, and taking it would steal it from the page's
  // own autofocus fields.
  bool _onKey(KeyEvent event) {
    if (!widget.keyboardShortcuts || event is! KeyDownEvent || !mounted) {
      return false;
    }
    final keyboard = HardwareKeyboard.instance;
    if (!(keyboard.isControlPressed || keyboard.isMetaPressed) ||
        keyboard.isAltPressed ||
        keyboard.isShiftPressed) {
      return false;
    }
    final index = _digits.indexOf(event.logicalKey);
    if (index < 0 ||
        index >= destinations.length ||
        !destinations[index].enabled) {
      return false;
    }
    // Only the scaffold of the page in front, not one under a pushed route.
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return false;
    onSelect(index);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final config = FoldMediaQuery.configOf(context);
    final chosen = AdaptiveNavStyle.of(context).merge(widget.style);
    final cupertino = _isCupertino(context, chosen.look);
    // The look's own colors and shapes, under the ones the app chose.
    final style = cupertino ? _cupertinoStyle(context).merge(chosen) : chosen;
    final drawerFrom = config.drawerFromWidth;
    return switch (context.formFactor) {
      FormFactor.phone => cupertino
          ? _cupertinoBarScaffold(context, chosen)
          : _bottomBarScaffold(context, style, maxBarWidth: style.barMaxWidth),
      FormFactor.cover => _coverScaffold(context, style, config),
      FormFactor.tablet
          when drawerFrom != null &&
              MediaQuery.sizeOf(context).width >= drawerFrom =>
        cupertino
            ? _sideBarScaffold(context, style, config, alwaysExpanded: true)
            : _drawerScaffold(context, style),
      FormFactor.tablet when _tabletSideBar(context, config) => !cupertino &&
              config.tabletRailStyle == TabletRailStyle.standard &&
              groups == null
          ? _railScaffold(context, style)
          : _sideBarScaffold(context, style, config),
      FormFactor.tablet => cupertino
          ? _cupertinoBarScaffold(context, chosen)
          : _bottomBarScaffold(
              context,
              style,
              maxBarWidth: style.barMaxWidth ?? config.tabletBottomBarMaxWidth,
            ),
    };
  }

  static bool _isCupertino(BuildContext context, NavLook? look) =>
      switch (look) {
        NavLook.cupertino => true,
        NavLook.platform => switch (Theme.of(context).platform) {
            TargetPlatform.iOS || TargetPlatform.macOS => true,
            _ => false,
          },
        NavLook.material || null => false,
      };

  /// iPadOS side bar colors: the accent on a light tint, rounded rows.
  static AdaptiveNavStyle _cupertinoStyle(BuildContext context) {
    final primary = CupertinoTheme.of(context).primaryColor;
    Color resolve(Color color) => CupertinoDynamicColor.resolve(color, context);
    return AdaptiveNavStyle(
      backgroundColor: resolve(CupertinoColors.secondarySystemBackground),
      indicatorColor: primary.withValues(alpha: 0.14),
      indicatorShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      selectedColor: primary,
      unselectedColor: resolve(CupertinoColors.secondaryLabel),
      groupBackgroundColor: resolve(CupertinoColors.tertiarySystemFill),
    );
  }

  /// Side bars without Material's ripple when the look is Cupertino.
  Widget _railTheme(
    BuildContext context,
    AdaptiveNavStyle style,
    Widget child,
  ) {
    if (!_isCupertino(context, style.look)) return child;
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      child: child,
    );
  }

  bool _tabletSideBar(BuildContext context, FoldAdaptiveConfig config) {
    final size = MediaQuery.sizeOf(context);
    return switch (config.tabletNavigation) {
      TabletNavigation.bottomBar => false,
      TabletNavigation.rail => true,
      TabletNavigation.railInLandscape => size.width > size.height,
    };
  }

  Widget _bottomBarScaffold(
    BuildContext context,
    AdaptiveNavStyle style, {
    double? maxBarWidth,
  }) {
    return _barScaffold(
      context,
      _FloatingNavBar(
        destinations: _barDestinations,
        currentIndex: _barIndex,
        onSelect: _onBarSelect,
        style: style,
        maxWidth: maxBarWidth,
      ),
    );
  }

  /// A [CupertinoTabBar]. It takes only the colors, icon size and height the
  /// app chose; the rest is the tab bar's own.
  Widget _cupertinoBarScaffold(BuildContext context, AdaptiveNavStyle chosen) {
    final tabs = _barDestinations;
    final iconSize = chosen.iconSize ?? 26;
    final disabled =
        CupertinoDynamicColor.resolve(CupertinoColors.quaternaryLabel, context);
    return _barScaffold(
      context,
      CupertinoTabBar(
        items: [
          for (final d in tabs)
            BottomNavigationBarItem(
              icon: d.buildIcon(
                selected: false,
                size: iconSize,
                color: d.enabled ? null : disabled,
              ),
              activeIcon: d.buildIcon(selected: true, size: iconSize),
              label: d.label,
            ),
        ],
        currentIndex: _barIndex,
        // The tab bar has no disabled items of its own.
        onTap: (i) {
          if (tabs[i].enabled) _onBarSelect(i);
        },
        activeColor: chosen.selectedColor,
        inactiveColor: chosen.unselectedColor ?? CupertinoColors.inactiveGray,
        backgroundColor: chosen.backgroundColor,
        iconSize: iconSize,
        height: chosen.barHeight ?? 50,
      ),
    );
  }

  Widget _barScaffold(BuildContext context, Widget bar) {
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
        // Groups show every tab, so nothing goes behind More; the rail
        // scrolls if they don't fit.
        side: _railTheme(
          context,
          railStyle,
          groups == null
              ? SideRail(
                  destinations: _barDestinations,
                  currentIndex: _barIndex,
                  onSelect: _onBarSelect,
                  trailingAction: trailingAction,
                  style: railStyle,
                )
              : SideRail(
                  destinations: destinations,
                  currentIndex: currentIndex,
                  onSelect: onSelect,
                  groups: groups,
                  openGroup: _openGroup.value,
                  onGroupTap: _toggleGroup,
                  trailingAction: trailingAction,
                  style: railStyle,
                ),
        ),
      ),
    );
  }

  Widget _drawerScaffold(BuildContext context, AdaptiveNavStyle style) {
    final colors = _NavColors(context, style);
    final iconSize = style.iconSize ?? 24;
    final groups = this.groups;
    final sections = groups == null
        ? [(null, destinations)]
        : [for (final g in groups) (g.label, g.destinations)];
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
                // The drawer has room for every tab, so groups become
                // headings rather than an accordion.
                for (final (i, (heading, tabs)) in sections.indexed) ...[
                  if (heading != null)
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                          28, i == 0 ? 8 : 20, 16, 8),
                      child: Text(
                        heading,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  for (final d in tabs)
                    NavigationDrawerDestination(
                      icon: d.buildIcon(selected: false, size: iconSize),
                      selectedIcon: d.buildIcon(selected: true, size: iconSize),
                      label: Text(d.label),
                      enabled: d.enabled,
                    ),
                ],
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }

  /// This package's own tablet side bar: expanded or an icon rail, flat or
  /// grouped.
  ///
  /// [alwaysExpanded] stands in for the drawer: expanded, no menu button.
  Widget _sideBarScaffold(
    BuildContext context,
    AdaptiveNavStyle style,
    FoldAdaptiveConfig config, {
    bool alwaysExpanded = false,
  }) {
    final expandable =
        alwaysExpanded || config.tabletRailStyle == TabletRailStyle.expanded;
    final collapsible =
        !alwaysExpanded && expandable && config.expandedRailCollapsible;
    final expanded = expandable &&
        (!collapsible ||
            (_railExpanded.value ?? !config.expandedRailStartsCollapsed));
    final localizations = MaterialLocalizations.of(context);
    final leading = [
      if (collapsible)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: expanded
                ? AlignmentDirectional.centerStart
                : AlignmentDirectional.center,
            child: IconButton(
              tooltip: expanded
                  ? localizations.expandedIconTapHint
                  : localizations.collapsedIconTapHint,
              icon: Icon(expanded ? Icons.menu_open : Icons.menu),
              onPressed: () => setState(() => _railExpanded.value = !expanded),
            ),
          ),
        ),
      if (trailingAction != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Align(
            alignment: expanded
                ? AlignmentDirectional.centerStart
                : AlignmentDirectional.center,
            child: trailingAction,
          ),
        ),
    ];
    return Scaffold(
      appBar: appBar,
      backgroundColor: widget.backgroundColor,
      body: Row(
        children: [
          AnimatedContainer(
            duration: _motion(context, const Duration(milliseconds: 250)),
            curve: Curves.easeOutCubic,
            width: expanded
                ? style.expandedRailWidth ??
                    AdaptiveNavScaffold.expandedRailWidth
                : style.railWidth ?? AdaptiveNavScaffold.railWidth,
            child: _railTheme(
              context,
              style,
              SideRail(
                destinations: destinations,
                currentIndex: currentIndex,
                onSelect: onSelect,
                groups: groups,
                openGroup: _openGroup.value,
                onGroupTap: _toggleGroup,
                expanded: expanded,
                alignment: config.tabletRailAlignment,
                leading: leading.isEmpty
                    ? null
                    : Column(mainAxisSize: MainAxisSize.min, children: leading),
                style: style,
              ),
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
  ///
  /// [base] replaces `labelMedium` under the style's own label styles.
  TextStyle label({
    required bool selected,
    bool disabled = false,
    bool boldSelected = false,
    TextStyle? base,
  }) {
    final color = disabled
        ? this.disabled
        : selected
            ? _style.selectedColor ?? _scheme.onSurface
            : unselected;
    return (base ?? _labelBase)
        .copyWith(
          color: color,
          fontWeight: selected && boldSelected ? FontWeight.w600 : null,
        )
        .merge(
            selected ? _style.selectedLabelStyle : _style.unselectedLabelStyle);
  }
}

/// The cover display's rail, and this package's tablet side bar: tabs along
/// an edge, with the trailing action after them.
///
/// With [groups], each group is a button that opens to show its tabs and
/// closes the others; [openGroup] is the open one. [expanded] lays each tab
/// out as a row, its label beside its icon, for a wide side bar.
class SideRail extends StatelessWidget {
  /// A rail of [destinations] with [currentIndex] selected.
  const SideRail({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onSelect,
    this.trailingAction,
    this.style = const AdaptiveNavStyle(),
    this.alignment,
    this.groups,
    this.openGroup,
    this.onGroupTap,
    this.expanded = false,
    this.leading,
  });

  /// The tabs, in order.
  final List<NavDestination> destinations;

  /// The selected tab, as an index into [destinations].
  final int currentIndex;

  /// Called with the index of the tab the user picks.
  final ValueChanged<int> onSelect;

  /// Shown after the tabs, such as a floating action button.
  final Widget? trailingAction;

  /// How the rail looks; fields left null keep their defaults.
  final AdaptiveNavStyle style;

  /// Where the tabs sit along the rail (default:
  /// [FoldAdaptiveConfig.coverRailAlignment] from the `FoldScope`).
  final CoverRailAlignment? alignment;

  /// Groups over [destinations], which must hold their tabs in order.
  final List<NavGroup>? groups;

  /// The open group, as an index into [groups]; null when all are closed.
  final int? openGroup;

  /// Called with a group's index when its button is tapped.
  final ValueChanged<int>? onGroupTap;

  /// Rows with the label beside the icon, instead of under it.
  final bool expanded;

  /// Pinned to the head of the rail whatever the [alignment], such as a menu
  /// button.
  final Widget? leading;

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
              child: _column(context, railAlignment),
            ),
          ),
        ),
      ),
    );
  }

  Widget _column(BuildContext context, MainAxisAlignment railAlignment) {
    final tabs = [
      ..._tabs(context),
      if (trailingAction != null) ...[
        const SizedBox(height: 16),
        trailingAction!,
      ],
      const SizedBox(height: 16),
    ];
    final crossAxis =
        expanded ? CrossAxisAlignment.stretch : CrossAxisAlignment.center;
    final leading = this.leading;
    if (leading == null) {
      return Column(
        mainAxisAlignment: railAlignment,
        crossAxisAlignment: crossAxis,
        children: [
          if (railAlignment != MainAxisAlignment.end) const SizedBox(height: 8),
          ...tabs,
        ],
      );
    }
    // The leading widget stays at the head; the tabs take the alignment in
    // the space below it. No Expanded: the column may be unbounded.
    return Column(
      mainAxisAlignment: railAlignment == MainAxisAlignment.start
          ? MainAxisAlignment.start
          : MainAxisAlignment.spaceBetween,
      crossAxisAlignment: crossAxis,
      children: [
        // Padding, not a SizedBox: a third child would take the head of the
        // spaceBetween column and push the leading widget down.
        Padding(padding: const EdgeInsets.only(top: 8), child: leading),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: crossAxis,
          children: tabs,
        ),
        if (railAlignment == MainAxisAlignment.center) const SizedBox(),
      ],
    );
  }

  Widget _tab(int i, {bool indented = false}) => expanded
      ? _ExpandedRailItem(
          destination: destinations[i],
          selected: i == currentIndex,
          onTap: () => onSelect(i),
          style: style,
          indented: indented,
        )
      : _RailItem(
          destination: destinations[i],
          selected: i == currentIndex,
          onTap: () => onSelect(i),
          style: style,
        );

  List<Widget> _tabs(BuildContext context) {
    final groups = this.groups;
    if (groups == null) {
      return [for (var i = 0; i < destinations.length; i++) _tab(i)];
    }
    final scheme = Theme.of(context).colorScheme;
    final duration = _motion(
      context,
      style.animationDuration ?? const Duration(milliseconds: 200),
    );
    final children = <Widget>[];
    var first = 0;
    for (var g = 0; g < groups.length; g++) {
      final group = groups[g];
      final count = group.destinations.length;
      final open = openGroup == g;
      final holdsCurrent =
          currentIndex >= first && currentIndex < first + count;
      final header = group.header(
        badge: group.destinations.any((d) => d.badge != null) ? '' : null,
      );
      // A closed group holding the current tab shows as selected, so the
      // user can still see where they are.
      children.add(expanded
          ? _ExpandedRailItem(
              destination: header,
              selected: holdsCurrent && !open,
              onTap: () => onGroupTap?.call(g),
              style: style,
              groupOpen: open,
            )
          : _RailItem(
              destination: header,
              selected: holdsCurrent && !open,
              onTap: () => onGroupTap?.call(g),
              style: style,
              groupOpen: open,
            ));
      children.add(AnimatedSize(
        duration: duration,
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: !open
            ? const SizedBox(width: double.infinity)
            : _RevealOnOpen(
                duration: duration,
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(
                      horizontal: expanded ? 12 : 6, vertical: 4),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: style.groupBackgroundColor ??
                        scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(expanded ? 20 : 16),
                  ),
                  child: Column(
                    crossAxisAlignment: expanded
                        ? CrossAxisAlignment.stretch
                        : CrossAxisAlignment.center,
                    children: [
                      for (var i = first; i < first + count; i++)
                        _tab(i, indented: true),
                    ],
                  ),
                ),
              ),
      ));
      first += count;
    }
    return children;
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    required this.style,
    this.groupOpen,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final AdaptiveNavStyle style;

  /// Set on a group's button: whether the group is open.
  final bool? groupOpen;

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
    final groupOpen = this.groupOpen;
    final labelStyle = colors.label(
      selected: selected,
      disabled: !enabled,
      boldSelected: true,
    );
    return Semantics(
      selected: selected,
      button: true,
      enabled: enabled,
      expanded: groupOpen,
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
                    style: labelStyle,
                  ),
                ],
                if (groupOpen != null)
                  AnimatedRotation(
                    turns: groupOpen ? 0.5 : 0,
                    duration:
                        _motion(context, const Duration(milliseconds: 200)),
                    child: Icon(
                      Icons.expand_more,
                      size: 16,
                      color: labelStyle.color,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Keeps a group's tabs in view while they open: on a short rail (a cover
/// display on its side) they would otherwise open below its end.
class _RevealOnOpen extends StatefulWidget {
  const _RevealOnOpen({required this.duration, required this.child});

  /// How long the group takes to open; the rail follows it that long.
  final Duration duration;
  final Widget child;

  @override
  State<_RevealOnOpen> createState() => _RevealOnOpenState();
}

class _RevealOnOpenState extends State<_RevealOnOpen> {
  Duration? _start;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback(_reveal);
  }

  // Runs after each frame of the opening animation, without a timer: once
  // the frames stop, so does this.
  void _reveal(Duration timestamp) {
    if (!mounted) return;
    final start = _start ??= timestamp;
    Scrollable.ensureVisible(
      context,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
    if (timestamp - start < widget.duration) {
      SchedulerBinding.instance.addPostFrameCallback(_reveal);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A tab of the expanded side bar: a full-width row, the label beside the
/// icon, inside the selection pill.
class _ExpandedRailItem extends StatelessWidget {
  const _ExpandedRailItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    required this.style,
    this.groupOpen,
    this.indented = false,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final AdaptiveNavStyle style;
  final bool? groupOpen;

  /// A tab inside an open group.
  final bool indented;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = _NavColors(context, style);
    final enabled = destination.enabled;
    final iconSize = style.iconSize ?? 24;
    final groupOpen = this.groupOpen;
    // A wide row has room for the larger label style.
    final labelStyle = colors.label(
      selected: selected,
      disabled: !enabled,
      boldSelected: true,
      base: Theme.of(context).textTheme.labelLarge,
    );
    final shape = style.indicatorShape ?? const StadiumBorder();
    return Semantics(
      selected: selected,
      button: true,
      enabled: enabled,
      expanded: groupOpen,
      label: destination.label,
      excludeSemantics: true,
      child: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: indented ? 4 : 12, vertical: 2),
        child: InkWell(
          onTap: enabled ? onTap : null,
          customBorder: shape,
          child: AnimatedContainer(
            duration: _motion(
              context,
              style.animationDuration ?? const Duration(milliseconds: 200),
            ),
            constraints: BoxConstraints(minHeight: math.max(48, iconSize + 24)),
            // A group's tabs sit in from its header.
            padding:
                EdgeInsetsDirectional.fromSTEB(indented ? 24 : 16, 8, 12, 8),
            decoration: ShapeDecoration(
              color: selected
                  ? style.indicatorColor ?? scheme.secondaryContainer
                  : Colors.transparent,
              shape: shape,
            ),
            child: Row(
              children: [
                destination.buildIcon(
                  selected: selected,
                  color: enabled
                      ? (selected ? colors.selected : colors.unselected)
                      : colors.disabled,
                  size: iconSize,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    destination.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
                  ),
                ),
                if (groupOpen != null)
                  AnimatedRotation(
                    turns: groupOpen ? 0.5 : 0,
                    duration:
                        _motion(context, const Duration(milliseconds: 200)),
                    child: Icon(Icons.expand_more, color: labelStyle.color),
                  ),
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
