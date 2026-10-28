## 1.4.1

* New screenshots from a Pixel 10 Pro Fold and an iPhone Duo: list and
  detail at the fold, tabletop, the cover thumb column and More.

## 1.4.0

* Add `AdaptiveListDetail`: a list and its open item, side by side at the
  fold or on wide tablets, one at a time on phones, where back closes the
  item.
* `AdaptiveNavScaffold` shows at most `maxBarDestinations` (5) tabs on the
  bottom bar and the cover rail; the rest go behind a "More" tab
  (`moreLabel`, `moreIcon`).
* Add `FoldAdaptiveConfig.drawerFromWidth`: a permanent `NavigationDrawer`
  on wide tablets.
* Add `AdaptiveNavScaffold.hideBarOnScroll`.
* Cover rail labels wrap onto two lines and the rail scrolls when its tabs
  don't fit, instead of overflowing with large text. Rail tabs keep a 48 pt
  touch target. Reduced motion turns off the rail, bar and hide animations.
* `FoldDevicePreset.galaxyZFlipCover` is now 411 × 427 pt, the Galaxy Z
  Flip5's cover at its usual density.
* Add `FoldSplitView.isSplitOf`, to show a back button only when a pane is
  alone.
* The example shows every feature: list and detail, tabletop, adaptive grid
  and sheets, More, drawer, hide-on-scroll and the debug overlay, with a
  test that runs it on every device preset.

## 1.3.0

* Opened flip phones (Galaxy Z Flip, Razr) follow `lockPhonesToPortrait` like
  any phone instead of turning freely. A phone-sized window with a fold in it
  counts as a flip; `FoldAdaptiveConfig.treatOpenedFlipsAsPhones: false`
  restores the old behaviour.
* Covers narrower than `FoldAdaptiveConfig.compactCoverRailBelow` (400 pt)
  get a compact, 64 pt rail without labels (`AdaptiveNavStyle.compactRailWidth`).
* Add `FoldAdaptiveConfig.coverMinShortestSide`, to give narrow covers the
  phone layout, and `FoldAdaptiveConfig.formFactorResolver`, to decide the
  form factor yourself.
* Add `FoldSplitView` and `resolveFoldSplit`: two panes that meet at the
  fold, or split a wide tablet window.
* Add `TabletopLayout` for half-open devices with the fold across.
* Add `FoldSafeArea` and `cameraInsets`, to keep content clear of camera
  housings.
* Add `WindowSizeClass`, `context.windowSizeClass`, `context.adaptive` and
  `AdaptiveBuilder`.
* Add `FoldListener` for posture and form factor changes.
* Add `showAdaptiveSheet`: a bottom sheet on phones, a dialog on tablets.
* Add `FoldDevicePreset` and `FoldPreview`, to render an app as on a
  foldable in tests and previews.
* Add `FoldDebugOverlay`.

## 1.2.1

* Fix the blank strip under the bottom bar on phones with a home indicator.
  A flat bar now fills that area to the screen edge; a floating bar overlaps
  its empty part (21 pt from the bottom on an iPhone instead of 34 pt).

## 1.2.0

* Add `FoldAdaptiveConfig.coverRailAlignment` (`top`, `center`, `bottom`):
  with `coverRailSide`, picks the corner of the cover display the tabs sit in.
* `SideRail` takes an optional `alignment`.

## 1.1.0

* Add `NavDestination.custom` for SVG, PNG or any widget as a tab icon.
  `NavDestination.icon` is now nullable.
* Add `AdaptiveNavStyle`, as a theme extension or `AdaptiveNavScaffold.style`:
  colors, indicator, label styles and visibility, icon size, bar height,
  corners and margin, rail width and alignment, animation speed.
* Add `NavDestination.badge` and `NavDestination.enabled`.
* Add `AdaptiveNavScaffold.backgroundColor`.

## 1.0.1

* Add screenshots from a Pixel Fold and an iPhone Duo.

## 1.0.0

* Initial release.
