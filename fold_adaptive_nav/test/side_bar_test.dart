import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsProperties;
import 'package:flutter_test/flutter_test.dart';
import 'package:fold_adaptive_nav/fold_adaptive_nav.dart';

const _tabs = [
  NavDestination(icon: Icons.home, label: 'Home'),
  NavDestination(icon: Icons.search, label: 'Search'),
  NavDestination(icon: Icons.mail, label: 'Inbox'),
  NavDestination(icon: Icons.settings, label: 'Settings'),
];

const _groups = [
  NavGroup(
    icon: Icons.account_balance,
    label: 'Banking',
    destinations: [
      NavDestination(icon: Icons.wallet, label: 'Accounts'),
      NavDestination(icon: Icons.credit_card, label: 'Cards', badge: '1'),
      NavDestination(icon: Icons.swap_horiz, label: 'Transfers'),
    ],
  ),
  NavGroup(
    icon: Icons.shopping_bag,
    label: 'Shopping',
    destinations: [
      NavDestination(icon: Icons.store, label: 'Shop'),
      NavDestination(icon: Icons.receipt, label: 'Orders'),
    ],
  ),
];

/// The opened Pixel Fold in landscape, and turned upright.
const _landscape = FoldDevicePreset.pixelFoldOpen;
final _portrait = FoldDevicePreset.pixelFoldOpen.rotated;

class _Host extends StatefulWidget {
  const _Host({this.grouped = false, this.initial = 0, this.selected});

  final bool grouped;
  final int initial;
  final List<int>? selected;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late int tab = widget.initial;

  void select(int i) {
    widget.selected?.add(i);
    setState(() => tab = i);
  }

  @override
  Widget build(BuildContext context) => widget.grouped
      ? AdaptiveNavScaffold.grouped(
          groups: _groups,
          currentIndex: tab,
          onSelect: select,
          trailingAction: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
          body: Text('page $tab'),
        )
      : AdaptiveNavScaffold(
          destinations: _tabs,
          currentIndex: tab,
          onSelect: select,
          body: Text('page $tab'),
        );
}

Widget _app(
  FoldDevicePreset preset, {
  FoldAdaptiveConfig config = const FoldAdaptiveConfig(),
  bool grouped = false,
  int initial = 0,
  List<int>? selected,
  MediaQueryData? media,
}) {
  Widget app = FoldPreview(
    preset: preset,
    config: config,
    child: MaterialApp(
      home: _Host(grouped: grouped, initial: initial, selected: selected),
    ),
  );
  if (media != null) app = MediaQuery(data: media, child: app);
  return app;
}

double _railWidth(WidgetTester tester) =>
    tester.getSize(find.byType(SideRail)).width;

void main() {
  group('split screen on an opened foldable', () {
    test('a squat half of the inner display is a phone, not a cover', () {
      for (final p in [
        FoldDevicePreset.iPhoneDuoSplitScreen,
        FoldDevicePreset.pixelFoldSplitScreen,
      ]) {
        expect(
            resolveFormFactor(window: p.size, fold: p.state), FormFactor.phone,
            reason: p.name);
      }
    });

    test('the same window size closed, or without a fold reading, is a cover',
        () {
      const size = Size(475, 669);
      expect(
        resolveFormFactor(
          window: size,
          fold: FoldDevicePreset.iPhoneDuoCover.state,
        ),
        FormFactor.cover,
      );
      expect(
        resolveFormFactor(window: size, fold: FoldState.unsupported),
        FormFactor.cover,
      );
    });

    testWidgets('split screen gets the bottom bar', (tester) async {
      await tester.pumpWidget(_app(FoldDevicePreset.iPhoneDuoSplitScreen));
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(SideRail), findsNothing);
    });
  });

  group('TabletNavigation.railInLandscape', () {
    const config =
        FoldAdaptiveConfig(tabletNavigation: TabletNavigation.railInLandscape);

    testWidgets('a side bar in landscape, a bottom bar in portrait',
        (tester) async {
      await tester.pumpWidget(_app(_landscape, config: config));
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      await tester.pumpWidget(_app(_portrait, config: config));
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('the default keeps the bottom bar in landscape',
        (tester) async {
      await tester.pumpWidget(_app(_landscape));
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('phones are not affected', (tester) async {
      await tester.pumpWidget(_app(
        FoldDevicePreset.phone.rotated,
        config: config,
      ));
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  group('expanded side bar', () {
    const config = FoldAdaptiveConfig(
      tabletNavigation: TabletNavigation.rail,
      tabletRailStyle: TabletRailStyle.expanded,
    );

    testWidgets('is 240 pt with labels beside the icons', (tester) async {
      await tester.pumpWidget(_app(_landscape, config: config));
      expect(find.byType(NavigationRail), findsNothing);
      expect(_railWidth(tester), 240);
      final icon = tester.getCenter(find.byIcon(Icons.search));
      final label = tester.getCenter(find.text('Search'));
      expect(label.dx, greaterThan(icon.dx));
      expect((label.dy - icon.dy).abs(), lessThan(4));
    });

    testWidgets('the menu button collapses it and expands it again',
        (tester) async {
      await tester.pumpWidget(_app(_landscape, config: config));
      await tester.tap(find.byIcon(Icons.menu_open));
      // Half way through the animation nothing overflows.
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(_railWidth(tester), 88);
      // Collapsed, labels sit under the icons.
      expect(tester.getCenter(find.text('Search')).dy,
          greaterThan(tester.getCenter(find.byIcon(Icons.search)).dy));

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(_railWidth(tester), 240);
    });

    testWidgets('the choice survives a trip through portrait', (tester) async {
      const turning = FoldAdaptiveConfig(
        tabletNavigation: TabletNavigation.railInLandscape,
        tabletRailStyle: TabletRailStyle.expanded,
      );
      await tester.pumpWidget(_app(_landscape, config: turning));
      await tester.tap(find.byIcon(Icons.menu_open));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(_portrait, config: turning));
      expect(find.byType(NavigationBar), findsOneWidget);
      await tester.pumpWidget(_app(_landscape, config: turning));
      await tester.pumpAndSettle();
      expect(_railWidth(tester), 88);
    });

    testWidgets('expandedRailStartsCollapsed and expandedRailCollapsible',
        (tester) async {
      await tester.pumpWidget(_app(
        _landscape,
        config: const FoldAdaptiveConfig(
          tabletNavigation: TabletNavigation.rail,
          tabletRailStyle: TabletRailStyle.expanded,
          expandedRailStartsCollapsed: true,
        ),
      ));
      expect(_railWidth(tester), 88);

      await tester.pumpWidget(_app(
        _landscape,
        config: const FoldAdaptiveConfig(
          tabletNavigation: TabletNavigation.rail,
          tabletRailStyle: TabletRailStyle.expanded,
          expandedRailCollapsible: false,
        ),
      ));
      await tester.pumpAndSettle();
      expect(_railWidth(tester), 240);
      expect(find.byIcon(Icons.menu_open), findsNothing);
    });

    testWidgets('expandedRailWidth sets the width', (tester) async {
      await tester.pumpWidget(FoldPreview(
        preset: _landscape,
        config: config,
        child: MaterialApp(
          theme: ThemeData(extensions: const [
            AdaptiveNavStyle(expandedRailWidth: 300),
          ]),
          home: const _Host(),
        ),
      ));
      expect(_railWidth(tester), 300);
    });

    testWidgets('tabletRailAlignment puts the tabs at the bottom',
        (tester) async {
      await tester.pumpWidget(_app(
        _landscape,
        config: const FoldAdaptiveConfig(
          tabletNavigation: TabletNavigation.rail,
          tabletRailStyle: TabletRailStyle.expanded,
          tabletRailAlignment: CoverRailAlignment.bottom,
        ),
      ));
      final rail = tester.getRect(find.byType(SideRail));
      // The menu button stays at the head; the tabs drop to the foot.
      expect(tester.getCenter(find.byIcon(Icons.menu_open)).dy,
          lessThan(rail.top + 100));
      expect(tester.getCenter(find.text('Settings')).dy,
          greaterThan(rail.bottom - 100));
    });

    testWidgets('large text wraps without overflowing', (tester) async {
      await tester.pumpWidget(_app(
        _landscape,
        config: config,
        grouped: true,
        media: const MediaQueryData(textScaler: TextScaler.linear(2.5)),
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('groups on side bars', () {
    const sideBar = FoldAdaptiveConfig(
      tabletNavigation: TabletNavigation.rail,
      tabletRailStyle: TabletRailStyle.expanded,
    );

    testWidgets(
        'the group of the current tab is open; tapping another opens '
        'it and closes the first', (tester) async {
      final selected = <int>[];
      await tester.pumpWidget(_app(
        _landscape,
        config: sideBar,
        grouped: true,
        selected: selected,
      ));
      expect(find.text('Accounts'), findsOneWidget);
      expect(find.text('Shop'), findsNothing);

      await tester.tap(find.text('Shopping'));
      await tester.pumpAndSettle();
      expect(find.text('Shop'), findsOneWidget);
      expect(find.text('Accounts'), findsNothing);
      expect(selected, isEmpty); // Opening a group selects nothing.

      await tester.tap(find.text('Orders'));
      await tester.pumpAndSettle();
      expect(selected, [4]);
      expect(find.text('page 4'), findsOneWidget);

      // Tapping the open group closes it.
      await tester.tap(find.text('Shopping'));
      await tester.pumpAndSettle();
      expect(find.text('Orders'), findsNothing);
    });

    testWidgets('a closed group holding the current tab reads as selected',
        (tester) async {
      // The group button's own Semantics, read from the widget so the test
      // runs on every supported Flutter version.
      SemanticsProperties shopping() => tester
          .widget<Semantics>(find.byWidgetPredicate(
              (w) => w is Semantics && w.properties.label == 'Shopping'))
          .properties;
      await tester.pumpWidget(_app(
        _landscape,
        config: sideBar,
        grouped: true,
        initial: 3,
      ));
      // Open, holding Shop: expanded, not marked selected.
      expect(shopping().expanded, isTrue);
      expect(shopping().selected, isFalse);

      await tester.tap(find.text('Shopping'));
      await tester.pumpAndSettle();
      expect(shopping().expanded, isFalse);
      expect(shopping().selected, isTrue);
    });

    testWidgets('the icon rail groups too', (tester) async {
      await tester.pumpWidget(_app(
        _landscape,
        config: const FoldAdaptiveConfig(
          tabletNavigation: TabletNavigation.rail,
        ),
        grouped: true,
      ));
      // Groups always get this package's side bar, here as an icon rail.
      expect(find.byType(NavigationRail), findsNothing);
      expect(_railWidth(tester), 88);
      expect(find.byIcon(Icons.menu_open), findsNothing);
      await tester.tap(find.text('Shopping'));
      await tester.pumpAndSettle();
      expect(find.text('Shop'), findsOneWidget);
    });

    testWidgets('the cover rail groups, and nothing goes behind More',
        (tester) async {
      await tester
          .pumpWidget(_app(FoldDevicePreset.pixelFoldCover, grouped: true));
      final rail = tester.widget<SideRail>(find.byType(SideRail));
      expect(rail.groups, hasLength(2));
      expect(find.text('More'), findsNothing);
      await tester.tap(find.text('Shopping'));
      await tester.pumpAndSettle();
      expect(find.text('Orders'), findsOneWidget);
    });

    testWidgets('a group opening below a short rail scrolls into view',
        (tester) async {
      // The Galaxy Z Fold cover on its side: 344 pt tall.
      await tester.pumpWidget(_app(
        FoldDevicePreset.galaxyZFoldCover.rotated,
        grouped: true,
      ));
      final rail = tester.getRect(find.byType(SideRail));
      await tester.ensureVisible(find.text('Shopping'));
      await tester.tap(find.text('Shopping'));
      await tester.pumpAndSettle();
      expect(rail.contains(tester.getCenter(find.text('Orders'))), isTrue);
    });

    testWidgets('the open group stays open after unfolding', (tester) async {
      await tester.pumpWidget(_app(FoldDevicePreset.pixelFoldCover,
          grouped: true, config: sideBar));
      await tester.tap(find.text('Shopping'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(_landscape, grouped: true, config: sideBar));
      await tester.pumpAndSettle();
      expect(find.text('Shop'), findsOneWidget);
      expect(find.text('Accounts'), findsNothing);
    });

    testWidgets('bottom bars show every tab without headings', (tester) async {
      await tester.pumpWidget(_app(FoldDevicePreset.phone, grouped: true));
      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.destinations, hasLength(5));
      expect(find.text('Banking'), findsNothing);
      expect(find.text('Orders'), findsOneWidget);

      await tester.pumpWidget(_app(_portrait,
          grouped: true,
          config: const FoldAdaptiveConfig(
            tabletNavigation: TabletNavigation.railInLandscape,
          )));
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Shopping'), findsNothing);
    });

    testWidgets('the drawer shows the groups as headings', (tester) async {
      await tester.pumpWidget(_app(
        const FoldDevicePreset(
          name: 'wide tablet',
          size: Size(1366, 1024),
          state: FoldState.unsupported,
        ),
        grouped: true,
        config: const FoldAdaptiveConfig(drawerFromWidth: 1200),
      ));
      expect(find.byType(NavigationDrawer), findsOneWidget);
      expect(find.text('Banking'), findsOneWidget);
      expect(find.text('Shopping'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
    });

    test('grouped flattens the tabs in order', () {
      final scaffold = AdaptiveNavScaffold.grouped(
        groups: _groups,
        currentIndex: 0,
        onSelect: (_) {},
        body: const SizedBox(),
      );
      expect(scaffold.destinations.map((d) => d.label),
          ['Accounts', 'Cards', 'Transfers', 'Shop', 'Orders']);
    });
  });
}
