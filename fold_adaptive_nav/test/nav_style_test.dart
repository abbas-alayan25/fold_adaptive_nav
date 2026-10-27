import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fold_adaptive_nav/fold_adaptive_nav.dart';

import 'helpers.dart';

const _phone = Size(393, 852);
const _cover = Size(466, 678);

Widget _tabs({
  AdaptiveNavStyle? style,
  List<NavDestination>? destinations,
  ValueChanged<int>? onSelect,
}) =>
    AdaptiveNavScaffold(
      destinations: destinations ??
          const [
            NavDestination(icon: Icons.home_outlined, label: 'Home'),
            NavDestination(icon: Icons.search, label: 'Search'),
            NavDestination(icon: Icons.person_outline, label: 'Profile'),
          ],
      currentIndex: 0,
      onSelect: onSelect ?? (_) {},
      style: style,
      body: const SizedBox(),
    );

/// Like [pumpScoped], with [AdaptiveNavStyle] as a theme extension.
Future<void> _pumpThemed(
  WidgetTester tester,
  Widget home, {
  required AdaptiveNavStyle themeStyle,
  FoldState? state,
}) async {
  await tester.pumpWidget(FoldScope(
    debugState: Stream.value(state ?? FoldState.unsupported),
    child: MaterialApp(
      theme: ThemeData(extensions: [themeStyle]),
      home: home,
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the scaffold style wins over the theme, field by field',
      (tester) async {
    setWindowSize(tester, _cover);
    await _pumpThemed(
      tester,
      _tabs(style: const AdaptiveNavStyle(railWidth: 120)),
      themeStyle: const AdaptiveNavStyle(
        railWidth: 100,
        backgroundColor: Color(0xFF123456),
      ),
      state: closedFoldable,
    );
    final rail = find.byType(SideRail);
    expect(tester.getSize(rail).width, 120);
    final material = tester.widget<Material>(
      find.descendant(of: rail, matching: find.byType(Material)).first,
    );
    expect(material.color, const Color(0xFF123456));
  });

  testWidgets('bottom bar height, color and margin', (tester) async {
    setWindowSize(tester, _phone);
    await pumpScoped(
      tester,
      _tabs(
        style: const AdaptiveNavStyle(
          barHeight: 80,
          barMargin: EdgeInsets.zero,
          barBorderRadius: BorderRadius.zero,
          backgroundColor: Color(0xFF654321),
        ),
      ),
    );
    final bar = tester.getRect(find.byType(NavigationBar));
    expect(bar.height, 80);
    expect(bar.left, 0);
    expect(bar.right, _phone.width);
    expect(bar.bottom, _phone.height);
    final material = tester.widget<Material>(find
        .ancestor(of: find.byType(NavigationBar), matching: find.byType(Material))
        .first);
    expect(material.color, const Color(0xFF654321));
  });

  for (final (name, size, state) in [
    ('phone', _phone, FoldState.unsupported),
    ('cover', _cover, closedFoldable),
  ]) {
    testWidgets('selected and unselected colors on the $name',
        (tester) async {
      setWindowSize(tester, size);
      await pumpScoped(
        tester,
        _tabs(
          style: const AdaptiveNavStyle(
            selectedColor: Color(0xFFFF0000),
            unselectedColor: Color(0xFF00FF00),
            iconSize: 30,
          ),
        ),
        state: state,
      );
      IconThemeData iconThemeOf(IconData icon) =>
          IconTheme.of(tester.element(find.byIcon(icon)));
      Icon iconOf(IconData icon) => tester.widget<Icon>(find.byIcon(icon));
      Color? colorOf(IconData icon) =>
          iconOf(icon).color ?? iconThemeOf(icon).color;

      expect(colorOf(Icons.home_outlined), const Color(0xFFFF0000));
      expect(colorOf(Icons.search), const Color(0xFF00FF00));
      expect(tester.getSize(find.byIcon(Icons.search)), const Size.square(30));
    });

    testWidgets('hidden labels on the $name still select and read out',
        (tester) async {
      setWindowSize(tester, size);
      int? selected;
      await pumpScoped(
        tester,
        _tabs(
          style: const AdaptiveNavStyle(
            labelBehavior: NavLabelBehavior.alwaysHide,
          ),
          onSelect: (i) => selected = i,
        ),
        state: state,
      );
      expect(find.bySemanticsLabel(RegExp('Profile')), findsOneWidget);
      await tester.tap(find.byIcon(Icons.person_outline));
      expect(selected, 2);
    });

    testWidgets('badges and disabled tabs on the $name', (tester) async {
      setWindowSize(tester, size);
      int? selected;
      await pumpScoped(
        tester,
        _tabs(
          destinations: const [
            NavDestination(icon: Icons.home_outlined, label: 'Home'),
            NavDestination(icon: Icons.mail_outline, label: 'Inbox', badge: '3'),
            NavDestination(
              icon: Icons.lock_outline,
              label: 'Locked',
              enabled: false,
            ),
          ],
          onSelect: (i) => selected = i,
        ),
        state: state,
      );
      expect(find.byType(Badge), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.lock_outline), warnIfMissed: false);
      expect(selected, isNull);
      await tester.tap(find.byIcon(Icons.mail_outline));
      expect(selected, 1);
    });
  }

  for (final (side, alignment) in [
    (RailSide.trailingPhysicalRight, CoverRailAlignment.top),
    (RailSide.trailingPhysicalRight, CoverRailAlignment.center),
    (RailSide.trailingPhysicalRight, CoverRailAlignment.bottom),
    (RailSide.physicalLeft, CoverRailAlignment.top),
  ]) {
    testWidgets('cover rail tabs: ${side.name}, ${alignment.name}',
        (tester) async {
      setWindowSize(tester, _cover);
      await pumpScoped(
        tester,
        AdaptiveNavScaffold(
          destinations: const [
            NavDestination(icon: Icons.home_outlined, label: 'Home'),
            NavDestination(icon: Icons.search, label: 'Search'),
          ],
          currentIndex: 0,
          onSelect: (_) {},
          trailingAction: FloatingActionButton(
            key: const Key('fab'),
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
          body: const SizedBox(),
        ),
        state: closedFoldable,
        config: FoldAdaptiveConfig(
          coverRailSide: side,
          coverRailAlignment: alignment,
        ),
      );
      expect(tester.takeException(), isNull);
      final home = tester.getRect(find.byIcon(Icons.home_outlined));
      final fab = tester.getRect(find.byKey(const Key('fab')));
      final third = _cover.height / 3;
      switch (alignment) {
        case CoverRailAlignment.top:
          expect(home.top, lessThan(third));
        case CoverRailAlignment.center:
          expect(home.top, greaterThan(third / 2));
          expect(fab.bottom, lessThan(_cover.height - third / 2));
        case CoverRailAlignment.bottom:
          expect(fab.bottom, greaterThan(_cover.height - third / 2));
      }
      if (side == RailSide.physicalLeft) {
        expect(home.right, lessThan(AdaptiveNavScaffold.railWidth + 1));
      } else {
        expect(home.left, greaterThan(_cover.width - AdaptiveNavScaffold.railWidth - 1));
      }
    });
  }

  testWidgets('the style railAlignment wins over the config',
      (tester) async {
    setWindowSize(tester, _cover);
    await pumpScoped(
      tester,
      _tabs(style: const AdaptiveNavStyle(railAlignment: MainAxisAlignment.start)),
      state: closedFoldable,
      config: const FoldAdaptiveConfig(
        coverRailAlignment: CoverRailAlignment.bottom,
      ),
    );
    expect(tester.getRect(find.byIcon(Icons.home_outlined)).top,
        lessThan(_cover.height / 4));
  });

  testWidgets('cover rail tabs at the top when aligned to start',
      (tester) async {
    setWindowSize(tester, _cover);
    await pumpScoped(
      tester,
      _tabs(style: const AdaptiveNavStyle(railAlignment: MainAxisAlignment.start)),
      state: closedFoldable,
    );
    expect(tester.getRect(find.byIcon(Icons.home_outlined)).top,
        lessThan(_cover.height / 4));
  });

  testWidgets('tablet rail follows the style', (tester) async {
    setWindowSize(tester, const Size(1366, 1024));
    await pumpScoped(
      tester,
      _tabs(
        style: const AdaptiveNavStyle(
          indicatorColor: Color(0xFF0000FF),
          labelBehavior: NavLabelBehavior.onlySelected,
        ),
      ),
      config: const FoldAdaptiveConfig(tabletNavigation: TabletNavigation.rail),
    );
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.indicatorColor, const Color(0xFF0000FF));
    expect(rail.labelType, NavigationRailLabelType.selected);
  });

  test('merge, copyWith, lerp and equality', () {
    const a = AdaptiveNavStyle(barHeight: 60, railWidth: 80);
    const b = AdaptiveNavStyle(barHeight: 100);
    expect(a.merge(b), const AdaptiveNavStyle(barHeight: 100, railWidth: 80));
    expect(a.merge(null), a);
    expect(a.copyWith(railWidth: 90).railWidth, 90);
    expect(a.lerp(b, 0.5).barHeight, 80);
    expect(a.hashCode, const AdaptiveNavStyle(barHeight: 60, railWidth: 80).hashCode);
  });
}
