import 'package:flutter/material.dart';

import 'config.dart';
import 'fold_media_query.dart';
import 'form_factor.dart';
import 'side_layout.dart';

/// One tab of an [AdaptiveNavScaffold].
@immutable
class NavDestination {
  const NavDestination({
    required IconData this.icon,
    required this.label,
    this.selectedIcon,
  })  : customIcon = null,
        customSelectedIcon = null;

  /// A tab with any widget as its icon, such as an SVG or PNG.
  ///
  /// The icon is laid out in a 24 × 24 box under an [IconTheme] carrying the
  /// selected or unselected color. [ImageIcon] picks that color up by itself;
  /// for an SVG, read it with `IconTheme.of(context).color`.
  const NavDestination.custom({
    required Widget icon,
    required this.label,
    Widget? selectedIcon,
  })  : icon = null,
        selectedIcon = null,
        customIcon = icon,
        customSelectedIcon = selectedIcon;

  final IconData? icon;
  final IconData? selectedIcon;
  final Widget? customIcon;
  final Widget? customSelectedIcon;
  final String label;

  /// The icon to draw, at 24 × 24 so custom images can't stretch the bar.
  Widget buildIcon({required bool selected, Color? color}) {
    final custom = selected ? customSelectedIcon ?? customIcon : customIcon;
    if (custom == null) {
      return Icon(selected ? selectedIcon ?? icon : icon, color: color);
    }
    final box = SizedBox.square(dimension: 24, child: custom);
    return color == null
        ? box
        : IconTheme.merge(data: IconThemeData(color: color), child: box);
  }
}

/// Tabs that move to where the thumb is:
///
/// | Form factor | Renders |
/// |---|---|
/// | phone | [body] + floating bottom bar; [trailingAction] above it |
/// | cover | [body] + a rail on the physical right, action at its foot |
/// | tablet | a bottom bar capped in width, or a [NavigationRail] |
class AdaptiveNavScaffold extends StatefulWidget {
  const AdaptiveNavScaffold({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onSelect,
    required this.body,
    this.trailingAction,
    this.appBar,
  }) : assert(destinations.length >= 2);

  final List<NavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final Widget body;

  /// A floating action button on phones and tablets; the foot of the rail on
  /// the cover display.
  final Widget? trailingAction;

  final PreferredSizeWidget? appBar;

  /// Width of the cover display's rail.
  static const double railWidth = 88;

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
  Widget get body => KeyedSubtree(key: _bodyKey, child: widget.body);

  @override
  Widget build(BuildContext context) {
    final config = FoldMediaQuery.configOf(context);
    return switch (context.formFactor) {
      FormFactor.phone => _bottomBarScaffold(context, maxBarWidth: null),
      FormFactor.cover => _coverScaffold(context, config),
      FormFactor.tablet => config.tabletNavigation == TabletNavigation.rail
          ? _railScaffold(context)
          : _bottomBarScaffold(
              context,
              maxBarWidth: config.tabletBottomBarMaxWidth,
            ),
    };
  }

  Widget _bottomBarScaffold(BuildContext context, {double? maxBarWidth}) {
    Widget bar = _FloatingNavBar(
      destinations: destinations,
      currentIndex: currentIndex,
      onSelect: onSelect,
    );
    if (maxBarWidth != null) {
      bar = Align(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxBarWidth),
          child: bar,
        ),
      );
    }
    return Scaffold(
      appBar: appBar,
      extendBody: true,
      body: body,
      floatingActionButton: trailingAction,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: bar,
    );
  }

  Widget _coverScaffold(BuildContext context, FoldAdaptiveConfig config) {
    return Scaffold(
      appBar: appBar,
      body: SideLayout(
        railSide: config.coverRailSide,
        sideWidth: AdaptiveNavScaffold.railWidth,
        content: body,
        side: SideRail(
          destinations: destinations,
          currentIndex: currentIndex,
          onSelect: onSelect,
          trailingAction: trailingAction,
        ),
      ),
    );
  }

  Widget _railScaffold(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onSelect,
            labelType: NavigationRailLabelType.all,
            leading: trailingAction,
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: d.buildIcon(selected: false),
                  selectedIcon: d.buildIcon(selected: true),
                  label: Text(d.label),
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
  });

  final List<NavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Material(
          color: colors.surfaceContainer,
          elevation: 3,
          shadowColor: colors.shadow,
          borderRadius: BorderRadius.circular(32),
          clipBehavior: Clip.antiAlias,
          // The bar floats above the safe area; don't pad it a second time.
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: NavigationBar(
              height: 68,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedIndex: currentIndex,
              onDestinationSelected: onSelect,
              destinations: [
                for (final d in destinations)
                  NavigationDestination(
                    icon: d.buildIcon(selected: false),
                    selectedIcon: d.buildIcon(selected: true),
                    label: d.label,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
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
  });

  final List<NavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final Widget? trailingAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainer,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            for (var i = 0; i < destinations.length; i++)
              _RailItem(
                destination: destinations[i],
                selected: i == currentIndex,
                onTap: () => onSelect(i),
              ),
            if (trailingAction != null) ...[
              const SizedBox(height: 16),
              trailingAction!,
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = selected ? colors.onSecondaryContainer : colors.onSurfaceVariant;
    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                height: 32,
                decoration: BoxDecoration(
                  color: selected ? colors.secondaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: destination.buildIcon(
                  selected: selected,
                  color: foreground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
