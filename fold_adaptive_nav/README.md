# fold_adaptive_nav

Detects foldables and their posture natively on iOS (iPhone Duo) and Android,
and switches your app's navigation by itself:

| Device and posture | Tabs | Main action of a flow | Orientations |
|---|---|---|---|
| Ordinary phone | Floating bottom bar | Pinned to the bottom | Portrait |
| Foldable, closed (cover display) | Rail on the physical right, under the thumb | Thumb column on the right | Portrait (configurable) |
| Foldable, opened | Same as tablet | Same as tablet | All |
| Tablet | Bottom bar capped at 560 pt (or a rail) | Bottom, or a side panel from 840 pt | All |

You add one widget and no device checks. For the content itself there are
panes that meet at the fold (`FoldSplitView`, `TabletopLayout`),
`FoldSafeArea`, per-form-factor values and device presets for tests.

## Devices

| Device | Status |
|---|---|
| Pixel Fold | Tested on the device (screenshots below) |
| iPhone Duo | Tested on the device (screenshots below) |
| Galaxy Z Fold, Galaxy Z Flip, other Android foldables | Should work through Jetpack WindowManager; covered by presets in the tests, not yet checked on the devices |
| Phones, tablets, iPad Split View, Stage Manager | Layout follows the window size |

## Screenshots

The example app on a closed and an opened foldable. Nothing in the app checks
the device; the layout follows `FoldScope`.

### Android (Pixel Fold)

| Closed: cover display | Opened |
|:---:|:---:|
| <img src="https://raw.githubusercontent.com/abbas-alayan25/fold_adaptive_nav/main/fold_adaptive_nav/screenshots/android_cover_tabs.png" height="420" alt="Cover display with a rail on the right"> | <img src="https://raw.githubusercontent.com/abbas-alayan25/fold_adaptive_nav/main/fold_adaptive_nav/screenshots/android_open_tabs.png" height="420" alt="Opened display with a bottom bar"> |
| <img src="https://raw.githubusercontent.com/abbas-alayan25/fold_adaptive_nav/main/fold_adaptive_nav/screenshots/android_cover_flow.png" height="420" alt="Flow step with a thumb column"> | <img src="https://raw.githubusercontent.com/abbas-alayan25/fold_adaptive_nav/main/fold_adaptive_nav/screenshots/android_open_flow.png" height="420" alt="Flow step with a side panel"> |

### iOS (iPhone Duo)

| Closed: cover display | Opened |
|:---:|:---:|
| <img src="https://raw.githubusercontent.com/abbas-alayan25/fold_adaptive_nav/main/fold_adaptive_nav/screenshots/ios_cover_tabs.png" height="420" alt="Cover display with a rail on the right"> | <img src="https://raw.githubusercontent.com/abbas-alayan25/fold_adaptive_nav/main/fold_adaptive_nav/screenshots/ios_open_tabs.png" height="300" alt="Opened display with a bottom bar"> |
| <img src="https://raw.githubusercontent.com/abbas-alayan25/fold_adaptive_nav/main/fold_adaptive_nav/screenshots/ios_cover_flow.png" height="420" alt="Flow step with a thumb column"> | <img src="https://raw.githubusercontent.com/abbas-alayan25/fold_adaptive_nav/main/fold_adaptive_nav/screenshots/ios_open_flow.png" height="300" alt="Flow step with a side panel"> |

## Setup

1. Add the package:

   ```sh
   flutter pub add fold_adaptive_nav
   ```

2. Wrap the app:

   ```dart
   void main() => runApp(
         FoldScope(
           config: const FoldAdaptiveConfig(
             coverRailSide: RailSide.trailingPhysicalRight,
             coverRailAlignment: CoverRailAlignment.bottom,
             tabletNavigation: TabletNavigation.bottomBar,
             coverOrientations: [DeviceOrientation.portraitUp],
             lockPhonesToPortrait: true,
           ),
           child: MaterialApp(home: const HomeShell()),
         ),
       );
   ```

   Opened flip phones (Galaxy Z Flip, Razr) count as phones and follow
   `lockPhonesToPortrait`; set `treatOpenedFlipsAsPhones: false` to let them
   turn.

   Don't call `SystemChrome.setPreferredOrientations` in `main()`. `FoldScope`
   sets orientations once the first fold reading arrives; locking portrait
   earlier pins an opened foldable until the stream catches up.

3. **iOS**
   - Build with **Xcode 27.1 / the iOS 27.1 SDK**. The SDK your app links
     against decides how much of the opened iPhone Duo it gets:

     | App linked against | On the opened iPhone Duo |
     |---|---|
     | iOS 26 SDK or earlier | Phone-sized window centred on the inner display |
     | iOS 27.0 SDK | Fills the display beside the status rail (about 80 pt short) |
     | iOS 27.1 SDK | Edge to edge, vertical bars, reserved regions |

     Check a binary with `otool -l Runner | grep -A4 LC_BUILD_VERSION` (`sdk 27.1`).
   - In `ios/Runner/Info.plist`, the **iPhone** list
     `UISupportedInterfaceOrientations` (not only `~ipad`) must contain all
     four orientations. Otherwise the opened Duo can't turn, whatever Dart
     asks. `FoldScope` locks ordinary phones back to portrait.
   - Optional, to get the horizontal status bar back on the cover display:
     in `ios/Runner/Base.lproj/Main.storyboard`, change the root controller to
     ```xml
     customClass="FoldFlutterViewController" customModule="fold_adaptive_nav_ios"
     ```
     Or, without touching the storyboard, set the Info.plist key
     `FoldAdaptiveNavDisableVerticalBar` to `YES`.
   - The plugin uses the UIScene lifecycle. Apps created with Flutter 3.38+
     already have a `SceneDelegate`.

4. **Android**: the `<activity>` in `AndroidManifest.xml` needs
   `android:resizeableActivity="true"` and
   `android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|screenLayout|density|uiMode"`.
   Without `smallestScreenSize|screenLayout`, folding restarts the Flutter
   engine. The default template already has these.

5. After changing Info.plist, the storyboard, Swift, Kotlin or the manifest,
   **stop the app and run it again**. Hot reload and hot restart don't apply
   native changes, and on the iPhone Duo it then looks as if landscape doesn't
   work.

## Tabs

```dart
AdaptiveNavScaffold(
  destinations: const [
    NavDestination(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
    NavDestination(icon: Icons.search, label: 'Search'),
    NavDestination(icon: Icons.person_outline, label: 'Profile'),
  ],
  currentIndex: tab,
  onSelect: (i) => setState(() => tab = i),
  trailingAction: FloatingActionButton(onPressed: scan, child: const Icon(Icons.qr_code)),
  body: pages[tab],
)
```

`trailingAction` is a floating action button on phones and tablets, and sits
at the foot of the rail on the cover display.

### Where the tabs sit on the cover display

Two settings in `FoldAdaptiveConfig` pick the corner of the closed foldable:

| | `CoverRailAlignment.top` | `.center` | `.bottom` (default) |
|---|---|---|---|
| `RailSide.trailingPhysicalRight` (default) | top right | middle right | bottom right |
| `RailSide.physicalLeft` | top left | middle left | bottom left |

```dart
FoldScope(
  config: const FoldAdaptiveConfig(
    coverRailSide: RailSide.trailingPhysicalRight,
    coverRailAlignment: CoverRailAlignment.top, // tabs in the top-right corner
  ),
  child: ...,
)
```

The trailing action moves with the tabs. Bottom is the default because it's
where the thumb rests.

### Narrow covers

Covers narrower than `compactCoverRailBelow` (400 pt) get a compact rail:
64 pt wide (`AdaptiveNavStyle.compactRailWidth`) with no labels, which screen
readers still read out. That covers the Galaxy Z Fold and Z Flip outer
displays; the Pixel Fold (412 pt) and iPhone Duo (466 pt) keep the full rail.

To give narrow covers the phone layout instead, with a bottom bar:

```dart
const FoldAdaptiveConfig(coverMinShortestSide: 380)
```

For anything else, decide the form factor yourself. Use a top-level or
static function so the config stays `const`:

```dart
FormFactor myFormFactor(Size window, FoldState fold, FormFactor suggested) =>
    window.width < 360 ? FormFactor.phone : suggested;

const FoldAdaptiveConfig(formFactorResolver: myFormFactor)
```

### Custom icons (SVG, PNG)

`NavDestination.custom` takes any widget as the icon. It is drawn in a
24 × 24 box, under an `IconTheme` with the selected or unselected color.

```dart
// PNG: ImageIcon picks up the tab's color by itself.
NavDestination.custom(
  icon: const ImageIcon(AssetImage('assets/home.png')),
  selectedIcon: const ImageIcon(AssetImage('assets/home_filled.png')),
  label: 'Home',
),

// SVG (flutter_svg): read the color from the IconTheme.
NavDestination.custom(
  icon: Builder(
    builder: (context) => SvgPicture.asset(
      'assets/search.svg',
      colorFilter: ColorFilter.mode(IconTheme.of(context).color!, BlendMode.srcIn),
    ),
  ),
  label: 'Search',
),
```

Leave out the `colorFilter` (or use `Image.asset`) to keep the image's own
colors.

### Badges and disabled tabs

```dart
NavDestination(icon: Icons.mail_outline, label: 'Inbox', badge: '3'), // '' = a dot
NavDestination(icon: Icons.lock_outline, label: 'Pro', enabled: false),
```

### Styling

`AdaptiveNavStyle` styles the bottom bar, the cover rail and the tablet rail
together. Every field is optional and falls back to Material 3. Set it for
the whole app as a theme extension, or on one scaffold with `style:`, which
wins field by field.

```dart
MaterialApp(
  theme: ThemeData(extensions: const [
    AdaptiveNavStyle(
      backgroundColor: Color(0xFF101418),
      indicatorColor: Color(0xFF2E7D6B),
      selectedColor: Colors.white,
      unselectedColor: Colors.white70,
      labelBehavior: NavLabelBehavior.onlySelected,
    ),
  ]),
  ...
)

AdaptiveNavScaffold(
  style: const AdaptiveNavStyle(
    barHeight: 72,
    barMargin: EdgeInsets.zero,          // edge to edge…
    barBorderRadius: BorderRadius.zero,  // …and flat
  ),
  ...
)
```

| Field | Default |
|---|---|
| `backgroundColor` | `surfaceContainer` |
| `indicatorColor`, `indicatorShape` | `secondaryContainer`, stadium |
| `selectedColor`, `unselectedColor` | `onSecondaryContainer`, `onSurfaceVariant` |
| `selectedLabelStyle`, `unselectedLabelStyle` | merged over `labelMedium` |
| `iconSize` | 24 (also the box for custom icons) |
| `labelBehavior` | `NavLabelBehavior.alwaysShow` |
| `elevation`, `shadowColor` | 3, `shadow` (bottom bar) |
| `barHeight`, `barBorderRadius`, `barMargin` | 68, 32, 12 at sides and bottom (see below) |
| `railWidth` | 88 (cover rail) |
| `railAlignment` | follows `coverRailAlignment`; set it for other alignments such as `spaceEvenly` |
| `animationDuration` | 200 ms on the cover rail |

`AdaptiveNavScaffold.backgroundColor` sets the scaffold behind the body.

On phones with a home indicator, a floating bar overlaps the empty part of
that area: on an iPhone it sits 21 pt from the bottom, not 34 pt. A flat bar
(`barMargin` with a bottom of 0) fills the area down to the screen edge and
keeps its tabs above the indicator.

### With go_router

`AdaptiveNavScaffold` takes an index and a callback, so it fits a
`StatefulShellRoute`, and each tab keeps its own history:

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, shell) => AdaptiveNavScaffold(
    destinations: destinations,
    currentIndex: shell.currentIndex,
    onSelect: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
    body: shell,
  ),
  branches: [...],
)
```

## Flows

```dart
Scaffold(
  appBar: AppBar(title: const Text('Review')),
  body: PinnedActionBody(
    step: 3,
    stepCount: 3,
    footer: CheckboxListTile(...),        // too wide for the thumb column
    action: ActionGroup(children: [
      FlowActionButton.secondary(label: 'Edit', onPressed: back),
      FlowActionButton(label: 'Send', icon: Icons.check, onPressed: send),
    ]),
    child: ListView(...),
  ),
)
```

- `FlowActionButton` switches to a tall layout (icon over a label of up to
  three lines, at least 96 pt high) inside a `ThumbColumnScope`.
- `ActionGroup` lays buttons side by side, or stacks them in the thumb column.
- `FlowProgress` / `FlowProgressColumn` show the step and a row or column of dots.
- `CoverActionRow` is for screens that aren't scrolling forms.

## Content

### Panes at the fold

```dart
FoldSplitView(
  start: const MessageList(),
  end: const MessageDetail(),
)
```

| Device | Shows |
|---|---|
| Book foldable opened, flat or half open | `start` \| `end`, meeting at the fold |
| Half open with the fold across (tabletop, Flex mode) | `start` above, `end` below the fold |
| Tablet window from 840 pt wide | `start` \| `end` at `wideSplit` (0.5) |
| Anything else | `start` alone |

`mode: FoldSplitMode.hinge` splits only at a real fold, `.tabletop` only
when half open with the fold across. A flat flip phone is one screen and
never splits. Both panes keep their state while the layout changes.

For a list and detail, show the detail on its own on phones while an item
is open:

```dart
FoldSplitView(
  start: MessageList(onOpen: (id) => setState(() => openId = id)),
  end: openId == null ? const EmptyDetail() : MessageDetail(id: openId!),
  singleBuilder: (context, list, detail) => openId == null
      ? list
      : PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) => setState(() => openId = null),
          child: detail,
        ),
)
```

### Tabletop

```dart
TabletopLayout(
  top: VideoPlayer(controller),
  bottom: const PlayerControls(),
)
```

`top` sits above the fold and `bottom` below while the device stands half
open; otherwise `top` fills the space above `bottom` (change that with
`flatBuilder`). The video keeps playing across the change.
`TabletopLayout.isTabletop(state)` answers the same question in code.

### Camera housings

`FoldSafeArea` is a `SafeArea` that also keeps its child clear of the camera
and sensor housings the platform reports, such as the iPhone Duo's on its
cover display. To keep content off the fold, use `FoldSplitView`.

### Values per form factor

```dart
final columns = context.adaptive(phone: 2, cover: 3, tablet: 4);
context.windowSizeClass; // compact, medium, expanded, large, extraLarge

AdaptiveBuilder(
  phone: (_) => const CompactList(),
  tablet: (_) => const GridOfCards(),   // cover falls back to phone
)
```

### Sheets

`showAdaptiveSheet(context: context, builder: ...)` shows a bottom sheet on
phones and the cover display, and a dialog of at most 560 pt on tablets and
opened foldables.

### Reacting to folding

```dart
FoldListener(
  onPostureChanged: (previous, current) {
    if (current == HingePosture.closed) player.pause();
  },
  onFormFactorChanged: (previous, current) => saveDraft(),
  child: ...,
)
```

The callbacks run after the frame that shows the change, so they may call
`setState`; the first reading isn't reported.

## Reading the state

```dart
context.formFactor;                       // FormFactor.phone / cover / tablet
FoldMediaQuery.postureOf(context);        // rebuilds on posture changes only
FoldMediaQuery.isFoldableOf(context);
FoldMediaQuery.regionsOf(context);        // fold and camera regions, logical px
FoldMediaQuery.horizontalSizeClassOf(context); // iOS
FoldPlatform.instance.hingeAngle;         // raw per-frame stream, for animations
FoldPlatform.instance.setVerticalSystemBarDisabled(true); // iOS 27.1+
```

`FormFactorOverride(formFactor: FormFactor.cover, child: ...)` pins the form
factor of a subtree, for previews and tests.

### Display features

By default `FoldScope` doesn't write the fold into `MediaQuery.displayFeatures`.
If it did, Flutter would keep every dialog, sheet and menu to one half of the
inner display. Opt in with `FoldScope(bridge: DisplayFeatureBridge.cutoutsOnly)`
or `.full`. `.full` publishes the fold only while the device is partly open.

## Debugging

```dart
MaterialApp(
  builder: (context, child) =>
      FoldDebugOverlay(enabled: kDebugMode, child: child!),
)
```

draws a label with the form factor, posture, hinge angle, window size and
size classes, the fold in red and camera housings in orange.

## Testing

### Device presets

`FoldPreview` renders an app as it would look on a device, without the
device, and stands in for `FoldScope`. Run one test on every preset:

```dart
for (final preset in FoldDevicePreset.all) {
  testWidgets('checkout on ${preset.name}', (tester) async {
    await tester.pumpWidget(FoldPreview(preset: preset, child: const MyApp()));
    ...
  });
}
```

Presets: `phone`, `tablet`, `iPhoneDuoCover`, `iPhoneDuoOpen`,
`pixelFoldCover`, `pixelFoldOpen`, `pixelFoldTabletop`, `galaxyZFoldCover`,
`galaxyZFoldOpen`, `galaxyZFlipCover`, `galaxyZFlipOpen`, `galaxyZFlipFlex`.
`preset.rotated` turns one a quarter. The sizes are approximate: close
enough to pick the device's layout, not a replacement for the device.
`FoldPreview` scales to fit, so `tester.getSize` gives the preset's sizes
while `getTopLeft` gives scaled screen positions.

### Driving `FoldScope`

```dart
final states = StreamController<FoldState>(sync: true);
await tester.pumpWidget(FoldScope(debugState: states.stream, child: MaterialApp(...)));
states.add(const FoldState(isFoldable: true, posture: HingePosture.closed, ...));
await tester.pump();
```

Use `StreamController(sync: true)`. Without it, each event lands a microtask
after `pump()`.

## Packages

This is a federated plugin:

| Package | Contents |
|---|---|
| `fold_adaptive_nav` | Widgets and the Dart API (this package) |
| `fold_adaptive_nav_platform_interface` | `FoldState`, the wire codec, `FoldPlatform` |
| `fold_adaptive_nav_ios` | Swift: `UIHingeInteraction`, reserved regions, size classes, vertical bar |
| `fold_adaptive_nav_android` | Kotlin: Jetpack WindowManager, hinge angle sensor |

On web and desktop the state is `FoldState.unsupported`, and layout follows
the window size alone.
