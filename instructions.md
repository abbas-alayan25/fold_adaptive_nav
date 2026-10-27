# `fold_adaptive_nav`: technical spec for a Flutter foldable package

A Flutter plugin that tells an app, from native code on iOS and Android,
whether it runs on a foldable and in which posture. It then switches the app's
navigation by itself:

| Device and posture | Tabs | Main action of a flow | Orientations |
|---|---|---|---|
| Ordinary phone | Bottom bar | Pinned to the bottom | Portrait |
| Foldable, closed (cover display) | Rail down the trailing edge, under the thumb | Thumb column on the trailing edge | Portrait (configurable) |
| Foldable, opened (inner display) | Same as tablet | Same as tablet | All |
| Tablet | Bottom bar (or rail, configurable) | Bottom, or a side panel when wide | All |

An app drops in one scaffold and gets this with no device checks of its own.

This spec builds on what SuperApp learned on the iPhone Duo (see
[Lessons from SuperApp](#lessons-from-superapp)). Names marked
**verify** come from the iOS 27.1 SDK as used by the `foldable` package
(1.0.5). Check them against the SDK headers before shipping.

---

## 1. Package layout

Use a **federated plugin**, so the iOS and Android code can ship and version
separately and a test fake can stand in for both.

```
fold_adaptive_nav/                     # app-facing package: widgets + Dart API
fold_adaptive_nav_platform_interface/  # FoldPlatform base class, data models, wire codec
fold_adaptive_nav_ios/                 # Swift: hinge, regions, size classes, vertical bar
fold_adaptive_nav_android/             # Kotlin: Jetpack WindowManager, hinge sensor
```

`pubspec.yaml` of the app-facing package:

```yaml
name: fold_adaptive_nav
environment:
  sdk: ^3.5.0
  flutter: ">=3.27.0"
flutter:
  plugin:
    platforms:
      ios:
        default_package: fold_adaptive_nav_ios
      android:
        default_package: fold_adaptive_nav_android
dependencies:
  flutter: { sdk: flutter }
  fold_adaptive_nav_platform_interface: ^1.0.0
  fold_adaptive_nav_ios: ^1.0.0
  fold_adaptive_nav_android: ^1.0.0
```

On every other platform (web, desktop), the Dart side gets
`FoldState.unsupported` and falls back to window size alone.

---

## 2. Data model (platform interface)

```dart
enum HingePosture { closed, partiallyOpen, fullyOpen, unknown }
enum SizeClass { compact, regular, unspecified }
enum RegionKind { fold, cameraOcclusion }

@immutable
class FoldRegion {
  final RegionKind kind;
  final Rect bounds;        // logical pixels, in the Flutter view's space
  final bool isActive;      // a fold is active only while partly open
}

@immutable
class FoldState {
  final bool isFoldable;          // the hardware has a hinge
  final HingePosture posture;
  final double? hingeAngle;       // degrees, 0 = shut, 180 = flat; null if unknown
  final List<FoldRegion> regions;
  final SizeClass horizontalSizeClass; // iOS only; unspecified on Android
  final SizeClass verticalSizeClass;

  static const unsupported = FoldState(
    isFoldable: false, posture: HingePosture.unknown, hingeAngle: null,
    regions: [], horizontalSizeClass: SizeClass.unspecified,
    verticalSizeClass: SizeClass.unspecified,
  );
}

abstract class FoldPlatform extends PlatformInterface {
  Future<FoldState> snapshot();          // one-shot, also answers "is it foldable"
  Stream<FoldState> get changes;         // posture, regions, size classes
  Stream<double> get hingeAngle;         // raw, per frame; keep it out of the widget tree
  Future<void> setVerticalSystemBarDisabled(bool disabled); // iOS; no-op on Android
}
```

### Channels and wire format

- `MethodChannel('fold_adaptive_nav/methods')`: `snapshot`,
  `setVerticalSystemBarDisabled`.
- `EventChannel('fold_adaptive_nav/state')`: full `FoldState` maps.
- `EventChannel('fold_adaptive_nav/angle')`: doubles only, throttled natively
  to the display refresh rate.

Every map carries `"v": 1`. The Dart codec ignores unknown keys and maps
unknown posture strings to `HingePosture.unknown`, so a future fourth posture
or a newer native side never crashes an older Dart side.

Detection goes through `snapshot()`, never the stream. An `EventChannel`
swallows activation failures, so a silent stream can't be told apart from a
missing plugin.

---

## 3. iOS implementation (iPhone Duo)

### 3.1 Requirements

- Build with **Xcode 27.1 / the iOS 27.1 SDK**. The SDK the app links
  against decides how much of the inner display it gets:

  | App linked against | On the opened iPhone Duo |
  |---|---|
  | iOS 26 SDK or earlier | Phone-sized window centred on the inner display |
  | iOS 27.0 SDK | Fills the display beside the status rail (about 80 pt short) |
  | iOS 27.1 SDK | Edge to edge, vertical bars, reserved regions |

  Document this in the README. The package can't change it; the app's build
  does. Check a binary with `otool -l Runner | grep -A4 LC_BUILD_VERSION`
  (`sdk 27.1`).
- Plugin deployment target: **iOS 15.0**, the lowest Xcode 27.1 accepts.
- Support both CocoaPods (`.podspec`) and Swift Package Manager
  (`Package.swift`).
- Adopt the **UIScene** plugin lifecycle (`FlutterSceneLifeCycleDelegate`).
  Plugins still on application lifecycle events log a deprecation warning
  today, and Flutter will require scenes in a future release.

### 3.2 Hinge posture and angle: `UIHingeInteraction` (verify)

```swift
@available(iOS 27.1, *)
final class HingeSource: NSObject {
  private var interaction: UIHingeInteraction?

  func start(on view: UIView, onChange: @escaping (HingeReading) -> Void) {
    let interaction = UIHingeInteraction { _, update in
      guard let hinge = update.hinge else {      // nil = no hinge on this device
        onChange(.none); return
      }
      let posture: String = switch hinge.status {
        case .closed: "closed"
        case .partiallyOpen: "partiallyOpen"
        case .fullyOpen: "fullyOpen"
        @unknown default: "unknown"
      }
      // hinge.angle is radians.
      let degrees = min(max(Double(hinge.angle) * 180 / .pi, 0), 180)
      onChange(HingeReading(posture: posture, degrees: degrees))
    }
    view.addInteraction(interaction)
    self.interaction = interaction
  }
}
```

Attach it to the Flutter view: `registrar.viewController?.view`, or the
view controller handed over by the scene lifecycle.

**Compile on older SDKs too.** Naming `UIHingeInteraction` in Swift forces
every consumer onto Xcode 27.1. Make the default path resolve it through the
Objective-C runtime, and keep the typed path behind a compiler flag:

- Class `UIHingeInteraction`, initialiser `initWithUpdateHandler:`.
- Check `class_conformsToProtocol(cls, objc_getProtocol("UIInteraction"))`
  before `addInteraction`. Adding a non-conforming object crashes.
- Gate every property read on `responds(to:)`. A failed lookup reports
  `isFoldable = false` instead of crashing.
- Typed path: `#if FOLD_NATIVE_API`, enabled with
  `OTHER_SWIFT_FLAGS = -DFOLD_NATIVE_API` in the podspec and
  `.define("FOLD_NATIVE_API")` in `Package.swift`.

### 3.3 Fold and camera regions: `reservedRegions` (verify)

```swift
let folds = view.reservedRegions(kind: .division, options: .includeInactive)
let cameras = view.reservedRegions(kind: .occlusion)
// each has .frame (CGRect, in view coordinates) and .isActive
```

- Runtime selector: `reservedRegionsOfKind:options:`. Class to probe:
  `UIViewReservedRegionKind`. Option `includeInactive` = `1 << 0`.
- Ask for folds with `.includeInactive`. The fold is inactive while flat but
  its position is still useful.
- Re-read regions in `viewDidLayoutSubviews` and on every hinge update, and
  emit only when they change.
- `isActive` lags the hinge: right after the device lies flat it can still
  read `true`. Treat a fold as active only while the posture is
  `partiallyOpen`.

### 3.4 Size classes

Read `view.traitCollection.horizontalSizeClass` / `verticalSizeClass` and
register for changes with
`registerForTraitChanges([UITraitHorizontalSizeClass.self, UITraitVerticalSizeClass.self])`
(iOS 17+; fall back to `traitCollectionDidChange` on 15–16). Cover display =
compact width, inner display = regular width. Split View changes the class
without any fold, so size classes are a better layout signal than the
posture.

### 3.5 Turning off the vertical system bar (cover display)

On iOS 27.1+, while the Duo is closed, the system moves the status bar and
native bars into a vertical strip down the trailing edge. A Flutter app that
draws its own tabs wants the classic horizontal status bar back:

```swift
@available(iOS 27.1, *)
override var preferredVerticalBarBehavior: UIVerticalBarBehavior { .disabled }
```

This is a view-controller override, so a plugin can't set it with a method
call alone. Offer two routes:

1. **Recommended, explicit:** ship `FoldFlutterViewController: FlutterViewController`
   with the override, and have the app point `Main.storyboard`'s root
   controller at it (`customClass="FoldFlutterViewController"
   customModule="fold_adaptive_nav_ios"`). Document this as a one-time setup
   step.
2. **Automatic, opt-in:** at plugin registration, if the selector
   `preferredVerticalBarBehavior` exists on `UIViewController`, add an
   implementation to `FlutterViewController` with `class_addMethod`
   (`FlutterViewController` doesn't override it itself, so this adds rather
   than swizzles). Gate it on an Info.plist key such as
   `FoldAdaptiveNavDisableVerticalBar = YES`, so nothing changes silently.
   **Verify** on device that UIKit reads the value after registration. If it
   doesn't, look in the 27.1 headers for an update request, like
   `setNeedsUpdateOfHomeIndicatorAutoHidden`.

Apple's guidance: treat `.disabled` as a stable, app-wide choice, and don't
flip it per screen.

### 3.6 Orientations on iPhone

Flutter can only rotate into orientations that Info.plist allows. For the
opened Duo to turn, the **iPhone** list (`UISupportedInterfaceOrientations`,
not only `~ipad`) must include all four. The Dart policy (section 5.3) then
locks ordinary phones back to portrait. Document this. A plugin can't edit
the app's Info.plist.

### 3.7 Simulator notes

- The iPhone Duo simulator has two displays: cover 466 × 678 pt
  (1398 × 2034 px @3x), inner 669 × 951 pt (2007 × 2853 px @3x).
- `xcrun simctl io <device> screenshot` defaults to the inner display. Pass
  `--display=<UUID>` from `xcrun simctl io <device> enumerate` to capture the
  cover.
- `simctl` can't fold or unfold the device. Use the Simulator app's menu, and
  test posture logic in Dart with a fake stream (section 7).

---

## 4. Android implementation

### 4.1 Requirements

- `minSdk 24` for the plugin. Fold features need API 30+ hardware but must
  degrade quietly below that.
- Dependency: `androidx.window:window:1.3.0` (or newer stable), plus
  `androidx.window:window-java` if using the callback adapter from Java.
- Kotlin coroutines (`lifecycleScope`) or `WindowInfoTrackerCallbackAdapter`.
- The plugin implements `ActivityAware`. Everything below needs the activity,
  not the application context.

### 4.2 Is it a foldable?

Combine two signals, either of which is enough:

```kotlin
val pm = activity.packageManager
val hasHingeSensor = Build.VERSION.SDK_INT >= 30 &&
    pm.hasSystemFeature(PackageManager.FEATURE_SENSOR_HINGE_ANGLE)
// …or a FoldingFeature has ever been reported in WindowLayoutInfo (4.3).
```

Cache `isFoldable = true` once seen. A closed foldable reports no
`FoldingFeature`, so its absence alone doesn't mean "not a foldable".

### 4.3 Posture and fold geometry: Jetpack WindowManager

```kotlin
lifecycleScope.launch {
  activity.repeatOnLifecycle(Lifecycle.State.STARTED) {
    WindowInfoTracker.getOrCreate(activity)
      .windowLayoutInfo(activity)
      .collect { info ->
        val fold = info.displayFeatures.filterIsInstance<FoldingFeature>().firstOrNull()
        val posture = when {
          fold == null -> if (isFoldable) "closed" else "unknown"   // see 4.4
          fold.state == FoldingFeature.State.HALF_OPENED -> "partiallyOpen"
          fold.state == FoldingFeature.State.FLAT -> "fullyOpen"
          else -> "unknown"
        }
        emit(posture, fold?.bounds, fold?.isSeparating, fold?.occlusionType, fold?.orientation)
      }
  }
}
```

- `fold.bounds` is in window **physical pixels**. Divide by
  `resources.displayMetrics.density` before sending to Dart.
- `isSeparating` / `occlusionType == FULL` mark a real hinge (dual-screen)
  rather than a flexible crease.
- Flutter already publishes folds on Android as
  `MediaQuery.displayFeatures` (`DisplayFeatureType.fold`/`hinge`, states
  `postureFlat`/`postureHalfOpened`). The plugin's job on Android is mostly
  `isFoldable` and the closed state, which Flutter doesn't give.

### 4.4 Closed vs open on Android

The app on the outer display of a book-style foldable (Pixel Fold, Galaxy Z
Fold) sees no `FoldingFeature`. To call it `closed` rather than a plain
phone:

1. `isFoldable` from 4.2 is true, **and**
2. no `FoldingFeature` is present, **and**
3. if the hinge sensor exists, its reading is under ~30°
   (`SensorManager.getDefaultSensor(Sensor.TYPE_HINGE_ANGLE)`, API 30+).
   Register it only while the activity is started; it costs battery.

If the sensor is missing, fall back on (1) and (2) together with the window
size class (section 5.1). A narrow window is the cover display.

Clamshell foldables (Galaxy Z Flip, Razr) usually stop the app when closed,
or show it on a tiny cover screen. Treat a closed clamshell as `closed`, and
let the window size decide the layout.

### 4.5 Window size

Use `WindowMetricsCalculator.getOrCreate().computeCurrentWindowMetrics(activity).bounds`
when Dart needs the size before the first frame. Otherwise Flutter's
`MediaQuery.size` is already correct.

### 4.6 Manifest the app needs

```xml
<activity
  android:resizeableActivity="true"
  android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|screenLayout|density|uiMode"
  … />
```

Without `smallestScreenSize|screenLayout`, folding recreates the activity and
restarts the Flutter engine. The default Flutter template already has these.
Check them in the README's setup section.

---

## 5. Dart side: the automatic behaviour

### 5.1 Form factor: one decision, used everywhere

```dart
enum FormFactor { phone, cover, tablet }

FormFactor resolveFormFactor({required Size window, required FoldState fold}) {
  // Size first: it follows Split View, Stage Manager and freeform windows.
  final shortest = window.shortestSide;
  if (shortest >= 600) return FormFactor.tablet;
  // A cover display is wider than any phone's but much less tall for its width:
  // phones run 1.78 (iPhone SE) to 2.2; the Duo's cover is 1.46.
  final squat = shortest >= 440 && window.longestSide / shortest < 1.6;
  if (squat || (fold.isFoldable && fold.posture == HingePosture.closed)) {
    return FormFactor.cover;
  }
  return FormFactor.phone;
}
```

Expose it as `context.formFactor`, backed by an `InheritedModel` so widgets
depend only on what they read (form factor, posture, angle, regions).
Always let a `FormFactorOverride` widget pin it, for tests and previews.

Thresholds are Material's window size classes: compact < 600 ≤ medium <
840 ≤ expanded. Make them configurable through `FoldAdaptiveConfig`.

### 5.2 `FoldScope`, the one widget the app adds

```dart
FoldScope(
  config: const FoldAdaptiveConfig(
    coverRailSide: RailSide.trailingPhysicalRight, // under the right thumb, also in RTL
    tabletNavigation: TabletNavigation.bottomBar,  // or .rail
    coverOrientations: [DeviceOrientation.portraitUp],
    lockPhonesToPortrait: true,
  ),
  child: MaterialApp.router(…),
)
```

It:

1. Subscribes to `FoldPlatform.changes` and publishes `FoldState` through an
   `InheritedModel` (`FoldMediaQuery`).
2. Doesn't write `MediaQuery.displayFeatures` by default. Flutter's
   `DisplayFeatureSubScreen` would then confine every dialog, sheet, menu and
   picker to one half of the inner display (951 pt → ~455 pt). Offer
   `bridge: DisplayFeatureBridge.none | cutoutsOnly | full`, with `full`
   publishing a fold only while `partiallyOpen` and never a zero-width one.
3. Runs the orientation policy (5.3).

### 5.3 Orientation policy

```dart
List<DeviceOrientation> orientationsFor(FoldState fold, FormFactor ff, FoldAdaptiveConfig c) {
  if (fold.isFoldable) {
    switch (fold.posture) {
      case HingePosture.closed: return c.coverOrientations;
      case HingePosture.partiallyOpen:
      case HingePosture.fullyOpen: return DeviceOrientation.values;
      case HingePosture.unknown: break; // no reading yet: use the window
    }
  }
  return switch (ff) {
    FormFactor.tablet => DeviceOrientation.values,
    _ => c.lockPhonesToPortrait ? [DeviceOrientation.portraitUp] : DeviceOrientation.values,
  };
}
```

- Call `SystemChrome.setPreferredOrientations` **only when the list
  changes**. Cache the last list and compare with `listEquals`.
- Don't lock portrait in `main()` before the first reading arrives. That
  would pin an opened Duo until the stream catches up.

### 5.4 `AdaptiveNavScaffold`: bottom bar ↔ side rail

```dart
AdaptiveNavScaffold(
  destinations: const [
    NavDestination(icon: Icons.home_outlined, label: 'Home'),
    …
  ],
  currentIndex: tab,
  onSelect: goToTab,
  trailingAction: ScanButton(),      // FAB on phone, foot of the rail on cover
  body: navigationShell,
)
```

| Form factor | Renders |
|---|---|
| phone | `body` + floating bottom bar; `trailingAction` above it at the trailing end |
| cover | `Row(textDirection: ltr)`: `Expanded(body)` + `SideRail` on the physical right |
| tablet | bottom bar capped at 560 pt and centred, or a `NavigationRail` if configured |

Layout rules learned the hard way:

- Build the rail as an **overlay or a fixed-width child**, never as the
  second child of a `Row(crossAxisAlignment: stretch)` without a width. It
  then takes the max width and a blurred panel eats a third of the screen.
- Pin `textDirection: TextDirection.ltr` on the row so the rail stays under
  the right thumb in Arabic and Hebrew. Give the rail's contents back the
  ambient direction.
- Cap the tablet bottom bar (`Align(heightFactor: 1)` +
  `ConstrainedBox(maxWidth: 560)`). Full width at 1366 pt looks broken.

### 5.5 Flow actions: `PinnedActionBody` and `ThumbColumn`

Navigation alone isn't enough. A flow's primary button must move too:

| Form factor | Primary action |
|---|---|
| phone | pinned at the bottom, content fades out under it |
| cover | thumb column on the right, **96 pt wide** (84 pt button + 12 pt gap), progress dots above, button as low as possible |
| tablet, < 840 pt | as phone, content kept to 640 pt |
| tablet, ≥ 840 pt | side panel (340 pt) with progress, footer and action |

Provide:

- `ThumbColumnScope`, an `InheritedWidget` that buttons inside read to switch
  to their tall layout (icon over a label of up to 3 lines, 96 pt min
  height, 13 pt text).
- `ActionGroup`: buttons side by side normally, stacked inside a thumb column.
- `FlowProgress` / `FlowProgressColumn`: step count and dots for the column.
- `CoverActionRow`, for screens that aren't scrolling forms.
- `footer:`, for content too wide for the column (checkbox, keypad), which
  moves into the scrolling content on cover.

Keep the column narrow. At 128 pt it took over a quarter of the 466 pt cover
screen. 96 pt was the right size.

---

## 6. Public API summary

```dart
// Setup
FoldScope({required Widget child, FoldAdaptiveConfig config, DisplayFeatureBridge bridge});

// Reading state
context.formFactor;                       // FormFactor
FoldMediaQuery.postureOf(context);        // HingePosture, rebuilds on posture only
FoldMediaQuery.isFoldableOf(context);
FoldMediaQuery.regionsOf(context);
FoldMediaQuery.horizontalSizeClassOf(context);
FoldPlatform.instance.hingeAngle;         // raw stream for animations

// Widgets
AdaptiveNavScaffold(...);
PinnedActionBody(child:, action:, footer:);
ThumbColumnScope / ActionGroup / FlowProgress / CoverActionRow;
FormFactorOverride(formFactor:, child:);  // tests and previews

// iOS
FoldFlutterViewController;                // turns off the vertical system bar
```

---

## 7. Testing

**Dart, no device:**

- `FoldScope(debugState: Stream<FoldState>)` drives the tree from a test.
  Use `StreamController(sync: true)`, or the event lands a microtask after
  `pump()`.
- Capture orientation requests with
  `setMockMethodCallHandler(SystemChannels.platform, …)` and assert on
  `SystemChrome.setPreferredOrientations` arguments: closed → portrait,
  open → 4, closed again → portrait.
- A device matrix via `tester.binding.setSurfaceSize`:

  | Device | Size (pt) | Expect |
  |---|---|---|
  | iPhone SE | 375 × 667 | phone |
  | iPhone 16 / on its side | 393 × 852 / 852 × 393 | phone |
  | iPhone 16 Pro Max | 440 × 956 | phone (aspect 2.17) |
  | iPhone Duo closed | 466 × 678 | cover |
  | iPhone Duo open / on its side | 669 × 951 / 951 × 669 | tablet |
  | iPad mini / landscape | 744 × 1133 / 1133 × 744 | tablet |
  | iPad Pro 13" landscape | 1366 × 1024 | tablet, wide |
  | iPad Split View ⅓ | 320 × 1024 | phone |
  | Pixel Fold outer / inner | ~ 412 × 869 / 841 × 701 | phone* / tablet |
  | Galaxy Z Fold outer | ~ 344 × 882 | phone* |

  \* `cover` once `FoldState.posture == closed` is fed in.
- For every flow and every form factor, in an LTR and an RTL locale: no
  overflow errors, the primary action is on the right and in the lower half
  on cover, and no `ThumbColumnScope` exists on tablet.

**Native:**

- iOS: XCTest for the runtime lookups (they must return "unavailable", not
  crash, on iOS 15–27.0), and the posture mapping.
- Android: Robolectric with `androidx.window:window-testing`
  (`WindowLayoutInfoPublisherRule`, `FoldingFeature(activity, state = HALF_OPENED)`).

**By hand:** iPhone Duo simulator closed, open, half-open, rotated. Android
emulator "7.6 Fold-in with outer display" and "8 Fold-out" profiles, using the
posture controls in the extended controls panel.

---

## 8. Setup the README must spell out

1. `flutter pub add fold_adaptive_nav`
2. Wrap the app: `FoldScope(child: MaterialApp(...))`.
3. iOS: build with Xcode 27.1+. Add all four orientations to
   `UISupportedInterfaceOrientations` (iPhone). Optionally set the root
   controller to `FoldFlutterViewController` to drop the vertical system bar.
4. Android: check `configChanges` and `resizeableActivity="true"` on the
   activity.
5. After changing Info.plist, the storyboard, Swift, Kotlin or the manifest:
   **stop and re-run**. Hot reload and hot restart don't apply native
   changes, and on the iPhone Duo it looks as if "landscape doesn't work".

---

## 9. Lessons from SuperApp

- Flutter on iOS never fills `MediaQuery.displayFeatures`; posture has to
  come over a channel.
- The window size alone gave the right layout on the Duo (cover 466 × 678
  → cover, inner 669 × 951 → tablet). The hinge was needed for
  **orientation**, and to tell a closed foldable from a phone on Android.
- The "black strip" on the closed Duo was the system's vertical bar, not
  Flutter. Only a view-controller override removes it.
- On iPhone, Info.plist allowing portrait only blocks landscape on the opened
  Duo whatever Dart asks for.
- Tablets showed the same right-hand rail as the cover screen, which read as
  "the foldable sidebar is still there". Make the tablet navigation
  explicit in config, with the bottom bar as the default.
- The `foldable` 1.0.5 plugin still uses application lifecycle events. Build
  the new plugin on the UIScene lifecycle from day one.

## 10. References

- Apple: [Preparing your app for iPhone Duo](https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo),
  [Three steps to make your app shine on iPhone Duo](https://developer.apple.com/iphone-duo/prepare/)
- [`foldable` on pub.dev](https://pub.dev/packages/foldable): reference
  implementation of the iOS hinge and region bridge.
- Android: [Jetpack WindowManager](https://developer.android.com/jetpack/androidx/releases/window),
  [Make your app fold aware](https://developer.android.com/guide/topics/large-screens/make-apps-fold-aware),
  [Window size classes](https://developer.android.com/develop/ui/compose/layouts/adaptive/use-window-size-classes)
- Flutter: [Federated plugins](https://docs.flutter.dev/packages-and-plugins/developing-packages#federated-plugins),
  [UIScene migration for plugins](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate#migration-guide-for-flutter-plugins),
  [flutter/flutter#192515](https://github.com/flutter/flutter/issues/192515)
  (display features on iOS)
