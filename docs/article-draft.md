<!--
Draft for Medium / dev.to / r/FlutterDev. Replace the GIF link with a
recording from a real device when you have one; the rendered GIF in
fold_adaptive_nav/screenshots/demo.gif works until then.
-->

# Your Flutter app on a foldable: what breaks, and a package that fixes it

Google's `flutter_adaptive_scaffold` is discontinued. If your app used it — or
`MediaQuery` width checks — to adapt to tablets, it treats a foldable as two
unrelated devices: a narrow phone when closed, a tablet when open. That
misses what makes foldables different, and it shows.

![Unfolding: the bar becomes a side bar, the list gains its detail](https://raw.githubusercontent.com/abbas-alayan25/fold_adaptive_nav/main/fold_adaptive_nav/screenshots/demo.gif)

## What breaks on a foldable

1. **The cover display isn't a phone.** The iPhone Duo's is 466 × 678 pt,
   wider than any phone for its height. A bottom bar there sits far from the
   thumb, which rests on the edge.
2. **Unfolding throws away state.** Width-based layouts swap whole widget
   trees: the scroll position, a half-typed message and the open item go.
3. **Panes ignore the hinge.** A 50/50 split is wrong on a device whose fold
   isn't in the middle of your window, and wrong again in split screen.
4. **Orientation locks fight the device.** Locking portrait for phones also
   pins an opened foldable; an opened flip phone, a phone again, rotates.
5. **Half open is a posture, not a size.** In tabletop, a video belongs
   above the fold and its controls below — no window size tells you that.

## One widget, no device checks

[`fold_adaptive_nav`](https://pub.dev/packages/fold_adaptive_nav) reads the
fold natively — Jetpack WindowManager and the hinge sensor on Android,
`UIHingeInteraction` on the iPhone Duo — and decides one form factor:
phone, cover or tablet.

```dart
void main() => runApp(FoldScope(child: MaterialApp(home: const Shell())));

AdaptiveNavScaffold(
  destinations: const [
    NavDestination(icon: Icons.home_outlined, label: 'Home'),
    NavDestination(icon: Icons.inbox_outlined, label: 'Inbox', badge: '3'),
    NavDestination(icon: Icons.person_outline, label: 'Profile'),
  ],
  currentIndex: tab,
  onSelect: (i) => setState(() => tab = i),
  body: pages[tab],
)
```

| Device | Tabs |
|---|---|
| Phone | Floating bottom bar |
| Closed foldable | A rail on the right, under the thumb |
| Opened foldable, tablet | Bottom bar, or a side bar in landscape — expanded, collapsible, grouped |
| Opened foldable in split screen | Back to the phone layout |

The page keeps its state through every change.

## Panes that respect the hinge

```dart
AdaptiveListDetail(
  list: MessageList(onOpen: (id) => setState(() => openId = id)),
  detail: openId == null ? null : MessageDetail(id: openId!),
  onCloseDetail: () => setState(() => openId = null),
)
```

On the opened device, list and detail meet exactly at the fold. On a phone,
one at a time, with back closing the detail. Open a message on the cover,
unfold: it is still open, now beside the list.

`TabletopLayout(top: video, bottom: controls)` handles the half-open
posture, and the video doesn't restart.

## Test devices you don't own

```dart
for (final device in FoldDevicePreset.all) {
  testWidgets('checkout on ${device.name}', (tester) async {
    await tester.pumpWidget(FoldPreview(preset: device, child: const MyApp()));
    expect(tester.takeException(), isNull);
  });
}
```

Fourteen presets: phones, tablets, the iPhone Duo, Pixel Fold, Galaxy Z
Fold and Z Flip — closed, open, tabletop, Flex mode and split screen.

## Coming from flutter_adaptive_scaffold?

There is a parameter-by-parameter
[migration guide](https://github.com/abbas-alayan25/fold_adaptive_nav/blob/main/docs/migrating-from-flutter_adaptive_scaffold.md).

## Help wanted

The package is tested on a Pixel Fold and an iPhone Duo. If you have a
Galaxy Z Fold or Z Flip, a Razr, an Honor or an Oppo foldable, a five-minute
[device report](https://github.com/abbas-alayan25/fold_adaptive_nav/issues/new?template=device_report.yml)
helps every app that uses it.
