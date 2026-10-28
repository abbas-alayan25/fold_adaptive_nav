# fold_adaptive_nav example

One app that runs on phones, foldables (closed and open) and tablets
without a single device check. Every layout below comes from `FoldScope`.

```sh
cd example
flutter run          # on a phone, a foldable, a tablet or an emulator
flutter test         # the same app on 12 device presets
```

| Tab | Shows |
|---|---|
| Device | What the package reads from the platform: form factor, posture, hinge angle, size classes, fold and camera regions |
| Inbox | `AdaptiveListDetail`: messages beside the open one at the fold, one at a time on phones; Reply opens `showAdaptiveSheet` |
| Transfer | `CoverActionRow` and a three-step flow on `PinnedActionBody` |
| Player | `TabletopLayout` and `FoldSafeArea`: video above the fold, controls below, when half open |
| Gallery | `context.adaptive`, `AdaptiveBuilder` and `context.windowSizeClass` choosing the grid |
| Settings | Material, Cupertino or platform look, and every `FoldAdaptiveConfig` option, live: rail side and corner, tablet bottom bar, side bar or side bar in landscape, icon or expanded side bar and its alignment, tab groups, drawer, narrow covers, flip phones, hide-on-scroll, RTL, debug overlay |

Six tabs don't fit a bottom bar: phones and the cover rail show four and
**More**, which lists Gallery and Settings. The tablet rail and drawer show
all six.

## 1. Wrap the app

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fold_adaptive_nav/fold_adaptive_nav.dart';

// No SystemChrome.setPreferredOrientations here: FoldScope sets them once
// the first fold reading arrives.
void main() => runApp(
      FoldScope(
        config: const FoldAdaptiveConfig(
          coverRailSide: RailSide.trailingPhysicalRight,
          coverRailAlignment: CoverRailAlignment.bottom,
          tabletNavigation: TabletNavigation.railInLandscape, // side bar on its side
          tabletRailStyle: TabletRailStyle.expanded,           // labels beside icons
          coverOrientations: [DeviceOrientation.portraitUp],
          lockPhonesToPortrait: true,
          drawerFromWidth: 1200,          // a drawer on wide tablets
          coverMinShortestSide: 0,        // 380: Galaxy Z Fold covers get a bottom bar
          treatOpenedFlipsAsPhones: true, // an opened Z Flip stays in portrait
        ),
        child: MaterialApp(
          builder: (context, child) =>
              FoldDebugOverlay(enabled: false, child: child!),
          home: const HomeShell(),
        ),
      ),
    );
```

## 2. Tabs that move to the thumb

```dart
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return FoldListener(
      onPostureChanged: (previous, current) =>
          debugPrint('posture: ${previous.name} → ${current.name}'),
      child: AdaptiveNavScaffold(
        destinations: const [
          NavDestination(icon: Icons.devices_fold_outlined, label: 'Device'),
          NavDestination(icon: Icons.inbox_outlined, label: 'Inbox', badge: '3'),
          NavDestination(icon: Icons.swap_horiz, label: 'Transfer'),
          NavDestination(icon: Icons.play_circle_outline, label: 'Player'),
          NavDestination(icon: Icons.photo_library_outlined, label: 'Gallery'),
          NavDestination(icon: Icons.tune, label: 'Settings'),
        ],
        currentIndex: _tab,
        onSelect: (i) => setState(() => _tab = i),
        hideBarOnScroll: true,
        trailingAction: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.qr_code_scanner),
        ),
        body: IndexedStack(index: _tab, children: const [/* pages */]),
      ),
    );
  }
}
```

| Device | Tabs |
|---|---|
| Phone | Floating bottom bar (four tabs and More) |
| Closed foldable | Rail on the right, under the thumb; compact below 400 pt |
| Opened foldable, tablet, portrait | Full-width bottom bar |
| Opened foldable, tablet, landscape | Expanded side bar; its menu button collapses it to icons |
| Opened foldable in split screen | Same as a phone |
| Tablet from 1200 pt | Navigation drawer |

### Tab groups

Turn on **Group the tabs** in Settings to see the same six tabs under four
groups. Side bars and the cover rail open one group at a time; phones keep
the plain bottom bar.

```dart
AdaptiveNavScaffold.grouped(
  groups: [
    NavGroup(icon: Icons.home_outlined, label: 'Home', destinations: [device, inbox]),
    NavGroup(icon: Icons.account_balance_wallet_outlined, label: 'Money', destinations: [transfer]),
    NavGroup(icon: Icons.perm_media_outlined, label: 'Media', destinations: [player, gallery]),
    NavGroup(icon: Icons.settings_outlined, label: 'App', destinations: [settings]),
  ],
  currentIndex: _tab, // 0–5 across the groups, in order
  onSelect: (i) => setState(() => _tab = i),
  body: IndexedStack(index: _tab, children: pages),
)
```

## 3. A list and its detail

```dart
AdaptiveListDetail(
  list: MessageList(onOpen: (i) => setState(() => _open = i)),
  detail: _open == null ? null : MessageDetail(index: _open!),
  emptyDetail: const Center(child: Text('Pick a message')),
  onCloseDetail: () => setState(() => _open = null),
)
```

Open a message on the cover display, then unfold: it stays open, beside the
list. On a phone, back closes it. `FoldSplitView.isSplitOf(context)` tells
the detail whether it needs its own back button.

## 4. Tabletop

```dart
FoldSafeArea(
  child: TabletopLayout(
    top: VideoScreen(controller),
    bottom: PlayerControls(controller),
  ),
)
```

Stand a Pixel Fold upright half open, or a Galaxy Z Flip in Flex mode: the
video moves above the fold and the controls below, without restarting.

## 5. A flow with its action under the thumb

```dart
Scaffold(
  appBar: AppBar(title: const Text('Review')),
  body: PinnedActionBody(
    step: 3,
    stepCount: 3,
    footer: CheckboxListTile(
      value: confirmed,
      onChanged: (v) => setState(() => confirmed = v!),
      title: const Text('I checked the details'),
    ),
    action: ActionGroup(children: [
      FlowActionButton.secondary(label: 'Edit', onPressed: back),
      FlowActionButton(label: 'Send', icon: Icons.check, onPressed: send),
    ]),
    child: ListView(children: summary),
  ),
)
```

## 6. Content per form factor

```dart
final columns = context.windowSizeClass >= WindowSizeClass.expanded
    ? 6
    : context.adaptive(phone: 2, cover: 3, tablet: 4);

AdaptiveBuilder(
  phone: (_) => const Text('Two columns'),
  cover: (_) => const Text('Three columns, the rail beside'),
  tablet: (_) => const Text('Four columns, six from 840 pt'),
);

showAdaptiveSheet<void>(           // a sheet on phones, a dialog on tablets
  context: context,
  builder: (context) => const PhotoDetails(),
);
```

## 7. Test every device without owning it

```dart
for (final preset in FoldDevicePreset.all) {
  testWidgets('example on ${preset.name}', (tester) async {
    await tester.pumpWidget(FoldPreview(
      preset: preset,
      child: MaterialApp(home: HomeShell()),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
```

The presets cover a phone, a tablet, the iPhone Duo (closed and open), the
Pixel Fold (closed, open and tabletop), the Galaxy Z Fold (closed and open)
and the Galaxy Z Flip (closed, open and Flex mode). See
[`test/presets_test.dart`](test/presets_test.dart).

## More examples

- [`examples/go_router_example`](https://github.com/abbas-alayan25/fold_adaptive_nav/tree/main/examples/go_router_example):
  go_router with a back stack per tab and deep links.
- `integration_test/foldable_test.dart`: the app on a real device or
  emulator, through the native plugin (`flutter test integration_test`).

## Native setup

- **iOS**: build with the iOS 27.1 SDK, and list all four orientations under
  `UISupportedInterfaceOrientations` (the iPhone list, not only `~ipad`) in
  `ios/Runner/Info.plist`.
- **Android**: the `<activity>` needs `android:resizeableActivity="true"` and
  `smallestScreenSize|screenLayout` in `android:configChanges`, so folding
  doesn't restart the engine.
- After changing native files, stop the app and run it again; hot reload
  doesn't apply them.
