import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fold_adaptive_nav/fold_adaptive_nav.dart';

import 'helpers.dart';

const _destinations = [
  NavDestination(icon: Icons.home_outlined, label: 'Home'),
  NavDestination(icon: Icons.search, label: 'Search'),
  NavDestination(icon: Icons.person_outline, label: 'Profile'),
];

Widget _tabs() => AdaptiveNavScaffold(
      destinations: _destinations,
      currentIndex: 0,
      onSelect: (_) {},
      trailingAction: FloatingActionButton(
        key: const Key('fab'),
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      body: const Center(child: Text('body')),
    );

Widget _flow() => Scaffold(
      body: PinnedActionBody(
        step: 2,
        stepCount: 3,
        footer: CheckboxListTile(
          value: true,
          onChanged: (_) {},
          title: const Text('I agree'),
        ),
        action: ActionGroup(children: [
          FlowActionButton.secondary(label: 'Back', onPressed: () {}),
          FlowActionButton(
            key: const Key('primary'),
            label: 'Continue to the next step',
            icon: Icons.arrow_forward,
            onPressed: () {},
          ),
        ]),
        child: ListView(children: [
          for (var i = 0; i < 30; i++) ListTile(title: Text('Row $i')),
        ]),
      ),
    );

void main() {
  // (name, size, fold state)
  const devices = [
    ('phone', Size(393, 852), FoldState.unsupported, FormFactor.phone),
    ('cover', Size(466, 678), closedFoldable, FormFactor.cover),
    ('Pixel Fold outer', Size(412, 869), closedFoldable, FormFactor.cover),
    ('Duo open', Size(669, 951), openFoldable, FormFactor.tablet),
    (
      'iPad Pro landscape',
      Size(1366, 1024),
      FoldState.unsupported,
      FormFactor.tablet
    ),
  ];

  for (final direction in TextDirection.values) {
    for (final (name, size, state, formFactor) in devices) {
      group('$name, ${direction.name}', () {
        testWidgets('tabs', (tester) async {
          setWindowSize(tester, size);
          await pumpScoped(tester, _tabs(), state: state, direction: direction);
          expect(tester.takeException(), isNull);

          switch (formFactor) {
            case FormFactor.phone:
              expect(find.byType(NavigationBar), findsOneWidget);
              expect(find.byType(SideRail), findsNothing);
            case FormFactor.cover:
              expect(find.byType(NavigationBar), findsNothing);
              final rail = tester.getRect(find.byType(SideRail));
              // On the physical right, under the thumb, in LTR and RTL.
              expect(rail.right, size.width);
              expect(rail.width, AdaptiveNavScaffold.railWidth);
              // The action sits at the foot of the rail.
              final fab = tester.getRect(find.byKey(const Key('fab')));
              expect(rail.contains(fab.center), isTrue);
              expect(fab.center.dy, greaterThan(size.height / 2));
            case FormFactor.tablet:
              expect(find.byType(SideRail), findsNothing);
              final bar = tester.getRect(find.byType(NavigationBar));
              // Full width by default, inside the 12 pt side margins.
              expect(bar.width, size.width - 24);
              expect(bar.center.dx, closeTo(size.width / 2, 1));
          }
        });

        testWidgets('flow', (tester) async {
          setWindowSize(tester, size);
          await pumpScoped(tester, _flow(), state: state, direction: direction);
          expect(tester.takeException(), isNull);

          final primary = tester.getRect(find.byKey(const Key('primary')));
          switch (formFactor) {
            case FormFactor.cover:
              expect(find.byType(ThumbColumnScope), findsOneWidget);
              expect(find.byType(FlowProgressColumn), findsOneWidget);
              expect(primary.left, greaterThan(size.width / 2));
              expect(primary.top, greaterThan(size.height / 2));
              expect(primary.height, greaterThanOrEqualTo(96));
              expect(primary.width, lessThanOrEqualTo(84));
            case FormFactor.phone:
              expect(find.byType(ThumbColumnScope), findsNothing);
              expect(primary.bottom, greaterThan(size.height - 120));
            case FormFactor.tablet:
              expect(find.byType(ThumbColumnScope), findsNothing);
              if (size.width >= 840) {
                // In the side panel, on the trailing edge (only the cover
                // display pins the physical right).
                const panel = PinnedActionBody.panelWidth;
                if (direction == TextDirection.ltr) {
                  expect(primary.left, greaterThan(size.width - panel - 1));
                } else {
                  expect(primary.right, lessThan(panel + 1));
                }
              } else {
                expect(primary.bottom, greaterThan(size.height - 120));
              }
          }
        });
      });
    }
  }

  bodyStateTests();

  testWidgets('tablet rail when configured', (tester) async {
    setWindowSize(tester, const Size(1366, 1024));
    await pumpScoped(
      tester,
      _tabs(),
      state: FoldState.unsupported,
      config: const FoldAdaptiveConfig(tabletNavigation: TabletNavigation.rail),
    );
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('cover rail on the physical left when configured',
      (tester) async {
    setWindowSize(tester, const Size(466, 678));
    await pumpScoped(
      tester,
      _tabs(),
      state: closedFoldable,
      config: const FoldAdaptiveConfig(coverRailSide: RailSide.physicalLeft),
    );
    expect(tester.getRect(find.byType(SideRail)).left, 0);
  });

  testWidgets('tapping a rail item selects it', (tester) async {
    setWindowSize(tester, const Size(466, 678));
    int? selected;
    await pumpScoped(
      tester,
      AdaptiveNavScaffold(
        destinations: _destinations,
        currentIndex: 0,
        onSelect: (i) => selected = i,
        body: const SizedBox(),
      ),
      state: closedFoldable,
    );
    await tester.tap(find.text('Profile'));
    expect(selected, 2);
  });

  for (final (name, size, state) in [
    ('phone', const Size(393, 852), FoldState.unsupported),
    ('cover', const Size(466, 678), closedFoldable),
  ]) {
    testWidgets('custom icons on the $name, sized and tinted', (tester) async {
      setWindowSize(tester, size);
      Widget probe(Key key) => Builder(
            builder: (context) => ColoredBox(
              key: key,
              color: IconTheme.of(context).color!,
              child: const SizedBox(width: 100, height: 100),
            ),
          );
      await pumpScoped(
        tester,
        AdaptiveNavScaffold(
          destinations: [
            NavDestination.custom(
              icon: probe(const Key('home')),
              selectedIcon: probe(const Key('home selected')),
              label: 'Home',
            ),
            NavDestination.custom(
              icon: probe(const Key('search')),
              label: 'Search',
            ),
          ],
          currentIndex: 0,
          onSelect: (_) {},
          body: const SizedBox(),
        ),
        state: state,
      );
      expect(tester.takeException(), isNull);

      final selected = find.byKey(const Key('home selected'));
      final unselected = find.byKey(const Key('search'));
      expect(tester.getSize(selected), const Size.square(24));
      expect(tester.getSize(unselected), const Size.square(24));
      Color colorOf(Finder f) => tester.widget<ColoredBox>(f).color;
      expect(colorOf(selected), isNot(colorOf(unselected)));
    });
  }
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () => setState(() => count++),
        child: Text('count $count'),
      );
}

void bodyStateTests() {
  testWidgets('the body keeps its state when the device folds', (tester) async {
    setWindowSize(tester, const Size(841, 701));
    final controller = await pumpScoped(
      tester,
      AdaptiveNavScaffold(
        destinations: _destinations,
        currentIndex: 0,
        onSelect: (_) {},
        body: const Center(child: _Counter()),
      ),
      state: openFoldable,
    );
    await tester.tap(find.text('count 0'));
    await tester.pump();
    expect(find.text('count 1'), findsOneWidget);

    // Fold: tablet → cover.
    setWindowSize(tester, const Size(412, 869));
    controller.add(closedFoldable);
    await tester.pumpAndSettle();
    expect(find.byType(SideRail), findsOneWidget);
    expect(find.text('count 1'), findsOneWidget);

    // And open again.
    setWindowSize(tester, const Size(841, 701));
    controller.add(openFoldable);
    await tester.pumpAndSettle();
    expect(find.byType(SideRail), findsNothing);
    expect(find.text('count 1'), findsOneWidget);
  });
}
