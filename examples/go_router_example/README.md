# fold_adaptive_nav with go_router

`StatefulShellRoute.indexedStack` gives each tab its own back stack;
`AdaptiveNavScaffold` only needs the shell's index and `goBranch`:

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, shell) => AdaptiveNavScaffold(
    destinations: tabs,
    currentIndex: shell.currentIndex,
    onSelect: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
    body: shell,
  ),
  branches: [...],
)
```

- The tabs move to the thumb on every device: bottom bar, cover rail, or the
  expanded side bar on an opened foldable in landscape.
- Each tab keeps its pages: open an order, switch tabs, come back.
- Tapping the current tab again returns to its first page.
- A deep link (`/orders/42`) opens the Orders tab with the order on top.

```sh
flutter run                 # on a phone, foldable or tablet
flutter test                # the same flows on all 14 device presets
```

See [`lib/main.dart`](lib/main.dart) for the routes and
[`test/router_test.dart`](test/router_test.dart) for the checks.
