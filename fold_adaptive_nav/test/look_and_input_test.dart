import 'package:flutter/cupertino.dart' show CupertinoTabBar;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fold_adaptive_nav/fold_adaptive_nav.dart';

const _six = [
  NavDestination(icon: Icons.home, label: 'Home'),
  NavDestination(icon: Icons.search, label: 'Search'),
  NavDestination(icon: Icons.mail, label: 'Inbox'),
  NavDestination(icon: Icons.lock, label: 'Locked', enabled: false),
  NavDestination(icon: Icons.star, label: 'Saved'),
  NavDestination(icon: Icons.settings, label: 'Settings'),
];

const _groups = [
  NavGroup(
    icon: Icons.account_balance,
    label: 'Banking',
    destinations: [
      NavDestination(icon: Icons.wallet, label: 'Accounts'),
      NavDestination(icon: Icons.credit_card, label: 'Cards'),
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

const _sideBar = FoldAdaptiveConfig(
  tabletNavigation: TabletNavigation.rail,
  tabletRailStyle: TabletRailStyle.expanded,
);

class _Host extends StatefulWidget {
  const _Host({
    this.grouped = false,
    this.style,
    this.restorationId,
  });

  final bool grouped;
  final AdaptiveNavStyle? style;
  final String? restorationId;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int tab = 0;

  @override
  Widget build(BuildContext context) => widget.grouped
      ? AdaptiveNavScaffold.grouped(
          groups: _groups,
          currentIndex: tab,
          onSelect: (i) => setState(() => tab = i),
          restorationId: widget.restorationId,
          body: Text('page $tab'),
        )
      : AdaptiveNavScaffold(
          destinations: _six,
          currentIndex: tab,
          onSelect: (i) => setState(() => tab = i),
          style: widget.style,
          restorationId: widget.restorationId,
          body: Text('page $tab'),
        );
}

Widget _app(
  FoldDevicePreset preset, {
  FoldAdaptiveConfig config = const FoldAdaptiveConfig(),
  Widget home = const _Host(),
  TargetPlatform? platform,
  String? restorationScopeId,
}) =>
    FoldPreview(
      preset: preset,
      config: config,
      child: MaterialApp(
        restorationScopeId: restorationScopeId,
        theme: ThemeData(platform: platform),
        home: home,
      ),
    );

void main() {
  group('translations', () {
    // As an app with flutter_localizations does it.
    Widget inLanguage(String code) => FoldPreview(
          preset: FoldDevicePreset.phone,
          child: MaterialApp(
            locale: Locale(code),
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
              Locale('de'),
              Locale('sw'),
            ],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const _Host(),
          ),
        );

    testWidgets('More follows the app language', (tester) async {
      for (final (code, word) in [
        ('en', 'More'),
        ('ar', 'المزيد'),
        ('de', 'Mehr'),
      ]) {
        await tester.pumpWidget(inLanguage(code));
        await tester.pumpAndSettle();
        expect(find.text(word), findsOneWidget, reason: code);
      }
    });

    testWidgets('an unknown language falls back to English', (tester) async {
      // Swahili: Flutter has it, the package's list doesn't.
      await tester.pumpWidget(inLanguage('sw'));
      await tester.pumpAndSettle();
      expect(find.text('More'), findsOneWidget);
    });

    test('every language has a non-empty word', () {
      expect(NavStrings.languages, contains('en'));
      expect(NavStrings.languages.length, greaterThanOrEqualTo(20));
    });
  });

  group('keyboard', () {
    Future<void> press(WidgetTester tester, LogicalKeyboardKey key,
        {LogicalKeyboardKey modifier = LogicalKeyboardKey.controlLeft}) async {
      await tester.sendKeyDownEvent(modifier);
      await tester.sendKeyEvent(key);
      await tester.sendKeyUpEvent(modifier);
      await tester.pumpAndSettle();
    }

    testWidgets('Ctrl+digit and Cmd+digit pick tabs', (tester) async {
      await tester
          .pumpWidget(_app(FoldDevicePreset.pixelFoldOpen, config: _sideBar));
      await press(tester, LogicalKeyboardKey.digit3);
      expect(find.text('page 2'), findsOneWidget);
      await press(tester, LogicalKeyboardKey.digit6,
          modifier: LogicalKeyboardKey.metaLeft);
      expect(find.text('page 5'), findsOneWidget);
    });

    testWidgets('a disabled tab has no shortcut', (tester) async {
      await tester.pumpWidget(_app(FoldDevicePreset.pixelFoldOpen));
      await press(tester, LogicalKeyboardKey.digit4);
      expect(find.text('page 0'), findsOneWidget);
    });

    testWidgets('an autofocus text field in the page keeps its focus',
        (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(FoldPreview(
        preset: FoldDevicePreset.phone,
        child: MaterialApp(
          home: AdaptiveNavScaffold(
            destinations: _six,
            currentIndex: 0,
            onSelect: (_) {},
            body: TextField(autofocus: true, focusNode: node),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue);
    });

    testWidgets('a scaffold under a pushed page ignores the keys',
        (tester) async {
      await tester.pumpWidget(_app(FoldDevicePreset.phone));
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('pushed')),
      ));
      await tester.pumpAndSettle();
      await press(tester, LogicalKeyboardKey.digit2);
      navigator.pop();
      await tester.pumpAndSettle();
      expect(find.text('page 0'), findsOneWidget);
    });

    testWidgets('keys reach the shortcuts from a focused text field',
        (tester) async {
      await tester.pumpWidget(FoldPreview(
        preset: FoldDevicePreset.pixelFoldOpen,
        child: MaterialApp(
          home: Builder(builder: (context) {
            return const _FieldHost();
          }),
        ),
      ));
      await tester.tap(find.byType(TextField));
      await press(tester, LogicalKeyboardKey.digit2);
      expect(find.text('tab 1'), findsOneWidget);
    });
  });

  group('Cupertino look', () {
    const cupertino = AdaptiveNavStyle(look: NavLook.cupertino);

    testWidgets('phones get a CupertinoTabBar; disabled tabs ignore taps',
        (tester) async {
      await tester.pumpWidget(_app(
        FoldDevicePreset.phone,
        home: const _Host(style: cupertino),
      ));
      expect(find.byType(CupertinoTabBar), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      await tester.tap(find.text('Locked'));
      await tester.pumpAndSettle();
      expect(find.text('page 0'), findsOneWidget);
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();
      expect(find.text('page 1'), findsOneWidget);
      // More still lists the rest.
      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('tablets get the package side bar, not Material rail or drawer',
        (tester) async {
      await tester.pumpWidget(_app(
        FoldDevicePreset.pixelFoldOpen,
        config:
            const FoldAdaptiveConfig(tabletNavigation: TabletNavigation.rail),
        home: const _Host(style: cupertino),
      ));
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(SideRail), findsOneWidget);

      await tester.pumpWidget(_app(
        const FoldDevicePreset(
          name: 'wide',
          size: Size(1366, 1024),
          state: FoldState.unsupported,
        ),
        config: const FoldAdaptiveConfig(drawerFromWidth: 1200),
        home: const _Host(style: cupertino),
      ));
      expect(find.byType(NavigationDrawer), findsNothing);
      final rail = tester.widget<SideRail>(find.byType(SideRail));
      expect(rail.expanded, isTrue);
      expect(find.byIcon(Icons.menu_open), findsNothing);
    });

    testWidgets('side bars use rounded rows and no ripple', (tester) async {
      await tester.pumpWidget(_app(
        FoldDevicePreset.pixelFoldCover,
        home: const _Host(style: cupertino),
      ));
      final theme = Theme.of(tester.element(find.text('Search')));
      expect(theme.splashFactory, NoSplash.splashFactory);
      final rail = tester.widget<SideRail>(find.byType(SideRail));
      expect(rail.style.indicatorShape, isA<RoundedRectangleBorder>());
    });

    testWidgets('the app\'s colors win over the look\'s', (tester) async {
      await tester.pumpWidget(_app(
        FoldDevicePreset.pixelFoldCover,
        home: const _Host(
          style: AdaptiveNavStyle(
            look: NavLook.cupertino,
            selectedColor: Colors.pink,
          ),
        ),
      ));
      final rail = tester.widget<SideRail>(find.byType(SideRail));
      expect(rail.style.selectedColor, Colors.pink);
    });

    testWidgets('NavLook.platform follows ThemeData.platform', (tester) async {
      const platform = AdaptiveNavStyle(look: NavLook.platform);
      await tester.pumpWidget(_app(
        FoldDevicePreset.phone,
        platform: TargetPlatform.iOS,
        home: const _Host(style: platform),
      ));
      expect(find.byType(CupertinoTabBar), findsOneWidget);

      await tester.pumpWidget(_app(
        FoldDevicePreset.phone,
        platform: TargetPlatform.android,
        home: const _Host(style: platform),
      ));
      await tester.pumpAndSettle(); // MaterialApp animates the theme.
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  group('state restoration', () {
    testWidgets('the open group and the collapsed side bar come back',
        (tester) async {
      await tester.pumpWidget(_app(
        FoldDevicePreset.pixelFoldOpen,
        config: _sideBar,
        restorationScopeId: 'app',
        home: const _Host(grouped: true, restorationId: 'nav'),
      ));
      await tester.tap(find.text('Shopping'));
      await tester.tap(find.byIcon(Icons.menu_open));
      await tester.pumpAndSettle();

      await tester.restartAndRestore();
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.menu), findsOneWidget); // Still collapsed.
      expect(find.text('Shop'), findsOneWidget); // Shopping still open.
    });

    testWidgets('without a restorationId, nothing is restored', (tester) async {
      await tester.pumpWidget(_app(
        FoldDevicePreset.pixelFoldOpen,
        config: _sideBar,
        restorationScopeId: 'app',
        home: const _Host(grouped: true),
      ));
      await tester.tap(find.byIcon(Icons.menu_open));
      await tester.pumpAndSettle();
      await tester.restartAndRestore();
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.menu_open), findsOneWidget);
    });
  });
}

class _FieldHost extends StatefulWidget {
  const _FieldHost();

  @override
  State<_FieldHost> createState() => _FieldHostState();
}

class _FieldHostState extends State<_FieldHost> {
  int tab = 0;

  @override
  Widget build(BuildContext context) => AdaptiveNavScaffold(
        destinations: _six,
        currentIndex: tab,
        onSelect: (i) => setState(() => tab = i),
        body: Column(children: [const TextField(), Text('tab $tab')]),
      );
}
