# Migrating from flutter_adaptive_scaffold

[`flutter_adaptive_scaffold`](https://pub.dev/packages/flutter_adaptive_scaffold)
is discontinued and gets no more updates. `fold_adaptive_nav` covers the
same ground — navigation that follows the window, one or two panes — and
adds what a window size can't tell you: whether the device is a foldable,
open or closed, and where its hinge is.

Most apps move in under an hour. Nothing has to change at once: the two
packages can live side by side while you move screen by screen.

## 1. Swap the dependency

```sh
flutter pub remove flutter_adaptive_scaffold
flutter pub add fold_adaptive_nav
```

and wrap the app once:

```dart
void main() => runApp(
      FoldScope(child: MaterialApp(home: const Shell())),
    );
```

## 2. The scaffold

**Before**

```dart
AdaptiveScaffold(
  selectedIndex: tab,
  onSelectedIndexChange: (i) => setState(() => tab = i),
  destinations: const [
    NavigationDestination(icon: Icon(Icons.inbox_outlined), selectedIcon: Icon(Icons.inbox), label: 'Inbox'),
    NavigationDestination(icon: Icon(Icons.article_outlined), label: 'Articles'),
    NavigationDestination(icon: Icon(Icons.chat_outlined), label: 'Chat'),
  ],
  body: (_) => const InboxList(),
  secondaryBody: (_) => const InboxDetail(),
  useDrawer: false,
)
```

**After**

```dart
AdaptiveNavScaffold(
  currentIndex: tab,
  onSelect: (i) => setState(() => tab = i),
  destinations: const [
    NavDestination(icon: Icons.inbox_outlined, selectedIcon: Icons.inbox, label: 'Inbox'),
    NavDestination(icon: Icons.article_outlined, label: 'Articles'),
    NavDestination(icon: Icons.chat_outlined, label: 'Chat'),
  ],
  body: AdaptiveListDetail(
    list: InboxList(onOpen: (id) => setState(() => openId = id)),
    detail: openId == null ? null : InboxDetail(id: openId!),
    onCloseDetail: () => setState(() => openId = null),
  ),
)
```

## 3. Parameter by parameter

| flutter_adaptive_scaffold | fold_adaptive_nav |
|---|---|
| `destinations` (`NavigationDestination` with icon widgets) | `destinations` (`NavDestination` with `IconData`, or `NavDestination.custom(icon: anyWidget)`) |
| `selectedIndex` | `currentIndex` |
| `onSelectedIndexChange` | `onSelect` |
| `body: (context) => ...` | `body: ...` (a widget, not a builder) |
| `secondaryBody`, `bodyRatio` | `FoldSplitView(start:, end:, wideSplit:)` or `AdaptiveListDetail` in `body` |
| `smallBody`, `largeBody`, ... | `AdaptiveBuilder(phone:, cover:, tablet:)` or `context.adaptive(...)` |
| `smallBreakpoint`, `mediumBreakpoint`, ... | `FoldAdaptiveConfig(mediumBreakpoint: 600, expandedBreakpoint: 840)`; `context.windowSizeClass` for content |
| `useDrawer`, `drawerBreakpoint` | `FoldAdaptiveConfig(drawerFromWidth: 1200)` (null: no drawer) |
| `leadingExtendedNavRail`, `extendedNavigationRailWidth` | `FoldAdaptiveConfig(tabletRailStyle: TabletRailStyle.expanded)`, `AdaptiveNavStyle(expandedRailWidth: ...)` |
| `navigationRailWidth` | `AdaptiveNavStyle(railWidth: ...)` |
| `trailingNavRail` | `trailingAction` (a FAB on bars, the foot or head of a rail) |
| `groupAlignment` | `FoldAdaptiveConfig(tabletRailAlignment: CoverRailAlignment.top / .center / .bottom)` |
| `appBar`, `appBarBreakpoint` | `appBar` |
| `bodyOrientation: Axis.vertical` | `FoldSplitView(mode: FoldSplitMode.tabletop)` or `TabletopLayout` |
| `internalAnimations`, `transitionDuration` | Built in; off with the platform's reduced-motion setting |
| `AdaptiveLayout` / `SlotLayout` | `AdaptiveBuilder`, `FoldSplitView`, `context.formFactor` |
| `Breakpoints.small.isActive(context)` | `context.formFactor == FormFactor.phone` or `context.windowSizeClass == WindowSizeClass.compact` |

## 4. What changes for your users

| Situation | flutter_adaptive_scaffold | fold_adaptive_nav |
|---|---|---|
| Closed foldable (cover display) | Treated as a phone or a small tablet, by width | Its own layout: tabs on a rail under the thumb, flow buttons in a thumb column |
| Opened foldable | A tablet layout, panes split at a ratio | Panes meet **at the hinge**; tabletop puts content above the fold |
| Split screen on an opened foldable | Window size only | Phone layout, even for squat halves |
| Folding or unfolding | Layouts rebuild | Scroll positions, text input and the open item survive |
| Orientation | Up to the app | Phones portrait, opened foldables free, flip phones like phones |
| iOS look | Material only | `AdaptiveNavStyle(look: NavLook.platform)` gives a `CupertinoTabBar` and iPadOS side bars |
| Many sections | One flat list | `AdaptiveNavScaffold.grouped`: an accordion of groups on side bars |
| Tests | Resize the test window | `FoldPreview` with 14 device presets, including split screen and tabletop |

## 5. Things to watch

- `body` is a widget, not a builder: if yours read `context` from the builder,
  wrap it in a `Builder`.
- Icons are `IconData`. For an `Icon` widget with extra settings, an SVG or a
  PNG, use `NavDestination.custom`.
- Remove your own `SystemChrome.setPreferredOrientations` calls: `FoldScope`
  sets orientations once it knows the device (`manageOrientations: false` to
  keep yours).
- More than five tabs: the bottom bar shows four and a "More" tab, translated
  into 21 languages. The side bars show them all.
- With go_router, pass `shell.currentIndex` and `shell.goBranch` from a
  `StatefulShellRoute`; see
  [`examples/go_router_example`](../examples/go_router_example).
