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
