import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fold_adaptive_nav/fold_adaptive_nav.dart';

const _seven = [
  NavDestination(icon: Icons.home, label: 'Home'),
  NavDestination(icon: Icons.search, label: 'Search'),
  NavDestination(icon: Icons.mail, label: 'Inbox'),
  NavDestination(icon: Icons.map, label: 'Map'),
  NavDestination(icon: Icons.star, label: 'Saved'),
  NavDestination(icon: Icons.settings, label: 'Settings', badge: '2'),
  NavDestination(icon: Icons.help, label: 'Help'),
];

const _wideTablet = FoldDevicePreset(
  name: 'iPad Pro landscape',
  size: Size(1366, 1024),
  state: FoldState.unsupported,
);

Widget _app(
  FoldDevicePreset preset, {
  int currentIndex = 0,
  ValueChanged<int>? onSelect,
  List<NavDestination> destinations = _seven,
  FoldAdaptiveConfig config = const FoldAdaptiveConfig(),
  bool hideBarOnScroll = false,
  Widget body = const SizedBox(),
  AdaptiveNavStyle? style,
}) =>
    FoldPreview(
      preset: preset,
      config: config,
      child: MaterialApp(
        home: AdaptiveNavScaffold(
          destinations: destinations,
          currentIndex: currentIndex,
          onSelect: onSelect ?? (_) {},
          hideBarOnScroll: hideBarOnScroll,
          style: style,
          body: body,
        ),
      ),
    );

void main() {
  group('More', () {
    testWidgets('the bar shows four tabs and More, which lists the rest',
        (tester) async {
      int? selected;
      await tester.pumpWidget(
          _app(FoldDevicePreset.phone, onSelect: (i) => selected = i));
      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.destinations, hasLength(5));
      expect(find.text('More'), findsOneWidget);
      expect(find.text('Saved'), findsNothing);

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(selected, isNull);
      for (final label in ['Saved', 'Settings', 'Help']) {
        expect(find.widgetWithText(ListTile, label), findsOneWidget);
      }
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(selected, 5);
      expect(find.byType(ListTile), findsNothing); // The sheet closed.
    });

    testWidgets('More is selected while a tab behind it is', (tester) async {
      await tester.pumpWidget(_app(FoldDevicePreset.phone, currentIndex: 6));
      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, 4);
    });

    testWidgets('More carries a dot when a tab behind it has a badge',
        (tester) async {
      await tester.pumpWidget(_app(FoldDevicePreset.phone));
      final badges = tester.widgetList<Badge>(find.byType(Badge));
      expect(badges, hasLength(1));
      expect(badges.single.label, isNull);
    });

    testWidgets('the cover rail overflows the same way', (tester) async {
      await tester.pumpWidget(_app(FoldDevicePreset.pixelFoldCover));
      final rail = tester.widget<SideRail>(find.byType(SideRail));
      expect(rail.destinations.map((d) => d.label),
          ['Home', 'Search', 'Inbox', 'Map', 'More']);
    });

    testWidgets('the tablet rail shows every tab', (tester) async {
      await tester.pumpWidget(_app(
        FoldDevicePreset.pixelFoldOpen,
        config:
            const FoldAdaptiveConfig(tabletNavigation: TabletNavigation.rail),
      ));
      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).destinations,
        hasLength(7),
      );
    });

    testWidgets('maxBarDestinations is configurable', (tester) async {
      await tester.pumpWidget(FoldPreview(
        preset: FoldDevicePreset.phone,
        child: MaterialApp(
          home: AdaptiveNavScaffold(
            destinations: _seven,
            currentIndex: 0,
            onSelect: (_) {},
            maxBarDestinations: 7,
            body: const SizedBox(),
          ),
        ),
      ));
      expect(find.text('More'), findsNothing);
      expect(find.text('Help'), findsOneWidget);
    });
  });

  group('drawer', () {
    testWidgets('wide tablets get a drawer from drawerFromWidth',
        (tester) async {
      int? selected;
      await tester.pumpWidget(_app(
        _wideTablet,
        config: const FoldAdaptiveConfig(drawerFromWidth: 1200),
        onSelect: (i) => selected = i,
      ));
      expect(find.byType(NavigationDrawer), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Help'), findsOneWidget); // No overflow in a drawer.
      await tester.tap(find.text('Help'));
      expect(selected, 6);
    });

    testWidgets('narrower tablets and the default keep the bar',
        (tester) async {
      await tester.pumpWidget(_app(
        FoldDevicePreset.pixelFoldOpen,
        config: const FoldAdaptiveConfig(drawerFromWidth: 1200),
      ));
      expect(find.byType(NavigationDrawer), findsNothing);
      await tester.pumpWidget(_app(_wideTablet));
      expect(find.byType(NavigationDrawer), findsNothing);
    });
  });

  group('hideBarOnScroll', () {
    Offset slide(WidgetTester tester) =>
        tester.widget<AnimatedSlide>(find.byType(AnimatedSlide)).offset;
    final list = ListView.builder(
      itemCount: 100,
      itemBuilder: (_, i) => SizedBox(height: 60, child: Text('row $i')),
    );

    testWidgets('slides the bar away scrolling down, back scrolling up',
        (tester) async {
      await tester.pumpWidget(
          _app(FoldDevicePreset.phone, hideBarOnScroll: true, body: list));
      expect(slide(tester), Offset.zero);

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(slide(tester), const Offset(0, 1));

      await tester.drag(find.byType(ListView), const Offset(0, 100));
      await tester.pumpAndSettle();
      expect(slide(tester), Offset.zero);
    });

    testWidgets('off by default', (tester) async {
      await tester.pumpWidget(_app(FoldDevicePreset.phone, body: list));
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(slide(tester), Offset.zero);
    });

    testWidgets('a new tab brings the bar back', (tester) async {
      await tester.pumpWidget(
          _app(FoldDevicePreset.phone, hideBarOnScroll: true, body: list));
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(FoldDevicePreset.phone,
          hideBarOnScroll: true, body: list, currentIndex: 1));
      expect(slide(tester), Offset.zero);
    });
  });

  group('accessibility', () {
    testWidgets('reduced motion turns the animations off', (tester) async {
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _app(FoldDevicePreset.phone, hideBarOnScroll: true),
      ));
      expect(tester.widget<AnimatedSlide>(find.byType(AnimatedSlide)).duration,
          Duration.zero);
      expect(
        tester
            .widget<NavigationBar>(find.byType(NavigationBar))
            .animationDuration,
        Duration.zero,
      );

      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _app(FoldDevicePreset.pixelFoldCover),
      ));
      for (final container in tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))) {
        expect(container.duration, Duration.zero);
      }
    });

    testWidgets(
        'large text wraps and the cover rail scrolls instead of '
        'overflowing', (tester) async {
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(3)),
        child: _app(FoldDevicePreset.galaxyZFlipCover),
      ));
      expect(tester.takeException(), isNull);
      final label = tester.widget<Text>(find.text('Inbox'));
      expect(label.maxLines, 2);
      final scroll = find.descendant(
        of: find.byType(SideRail),
        matching: find.byType(SingleChildScrollView),
      );
      expect(scroll, findsOneWidget);
      await tester.drag(scroll, const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('rail tabs keep a 48 pt touch target with small icons',
        (tester) async {
      await tester.pumpWidget(_app(
        FoldDevicePreset.galaxyZFoldCover,
        destinations: _seven.take(3).toList(),
        style: const AdaptiveNavStyle(iconSize: 12),
      ));
      final item = find
          .ancestor(of: find.byIcon(Icons.home), matching: find.byType(InkWell))
          .first;
      final size = tester.getSize(item);
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    });
  });

  group('AdaptiveListDetail', () {
    Widget host(FoldDevicePreset preset, {int? initial}) => FoldPreview(
          preset: preset,
          child: MaterialApp(home: _ListDetailHost(initial: initial)),
        );

    testWidgets('one at a time on a phone; back closes the detail',
        (tester) async {
      await tester.pumpWidget(host(FoldDevicePreset.phone));
      expect(find.text('item 3'), findsOneWidget);
      expect(find.text('pick one'), findsNothing);

      await tester.tap(find.text('item 3'));
      await tester.pumpAndSettle();
      expect(find.text('detail 3'), findsOneWidget);
      expect(find.text('item 3'), findsNothing);
      expect(FoldSplitView.isSplitOf(tester.element(find.text('detail 3'))),
          isFalse);

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      await navigator.maybePop();
      await tester.pumpAndSettle();
      expect(find.text('detail 3'), findsNothing);
      expect(find.text('item 3'), findsOneWidget);
    });

    testWidgets('side by side at the fold, with the empty detail',
        (tester) async {
      await tester.pumpWidget(host(FoldDevicePreset.pixelFoldOpen));
      await tester.pumpAndSettle();
      expect(find.text('item 3'), findsOneWidget);
      expect(find.text('pick one'), findsOneWidget);
      expect(tester.getSize(find.byKey(const Key('list'))).width, 420.5);
      expect(
        FoldSplitView.isSplitOf(tester.element(find.byKey(const Key('list')))),
        isTrue,
      );
    });

    testWidgets('a wide tablet splits at listFraction', (tester) async {
      await tester.pumpWidget(host(const FoldDevicePreset(
        name: 'iPad landscape',
        size: Size(1133, 744),
        state: FoldState.unsupported,
      )));
      expect(tester.getSize(find.byKey(const Key('list'))).width,
          closeTo(1133 * 0.4, 0.01));
    });

    testWidgets('an item opened on the cover stays open after unfolding',
        (tester) async {
      await tester.pumpWidget(host(FoldDevicePreset.pixelFoldCover));
      await tester.tap(find.text('item 3'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(host(FoldDevicePreset.pixelFoldOpen));
      await tester.pumpAndSettle();
      expect(find.text('detail 3'), findsOneWidget);
      expect(find.text('item 3'), findsOneWidget);
    });
  });
}

class _ListDetailHost extends StatefulWidget {
  const _ListDetailHost({this.initial});

  final int? initial;

  @override
  State<_ListDetailHost> createState() => _ListDetailHostState();
}

class _ListDetailHostState extends State<_ListDetailHost> {
  late int? open = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AdaptiveListDetail(
        list: ListView(
          key: const Key('list'),
          children: [
            for (var i = 0; i < 5; i++)
              ListTile(
                title: Text('item $i'),
                onTap: () => setState(() => open = i),
              ),
          ],
        ),
        detail: open == null ? null : Center(child: Text('detail $open')),
        emptyDetail: const Center(child: Text('pick one')),
        onCloseDetail: () => setState(() => open = null),
      ),
    );
  }
}
