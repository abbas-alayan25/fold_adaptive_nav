import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fold_adaptive_nav/fold_adaptive_nav.dart';
import 'package:go_router_example/main.dart';

Widget _app(FoldDevicePreset preset, {String location = '/home'}) =>
    FoldPreview(
      preset: preset,
      config: const FoldAdaptiveConfig(
        tabletNavigation: TabletNavigation.railInLandscape,
        tabletRailStyle: TabletRailStyle.expanded,
      ),
      child: MaterialApp.router(
        routerConfig: buildRouter(initialLocation: location),
      ),
    );

void main() {
  for (final preset in FoldDevicePreset.all) {
    testWidgets('each tab keeps its own pages on ${preset.name}',
        (tester) async {
      await tester.pumpWidget(_app(preset));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.receipt_long_outlined).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Order #42'));
      await tester.pumpAndSettle();
      expect(find.text('Deep link: /orders/42'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.home_outlined).first);
      await tester.pumpAndSettle();
      expect(find.text('Deep link: /orders/42'), findsNothing);

      // Back on Orders, the order is still open.
      await tester.tap(find.byIcon(Icons.receipt_long_outlined).first);
      await tester.pumpAndSettle();
      expect(find.text('Deep link: /orders/42'), findsOneWidget);

      // Tapping the current tab again goes back to its list.
      await tester.tap(find.byIcon(Icons.receipt_long).first);
      await tester.pumpAndSettle();
      expect(find.text('Order #40'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a deep link opens its tab with the page on top', (tester) async {
    await tester.pumpWidget(
        _app(FoldDevicePreset.pixelFoldOpen, location: '/orders/57'));
    await tester.pumpAndSettle();
    expect(find.text('Deep link: /orders/57'), findsOneWidget);
    final rail = tester.widget<SideRail>(find.byType(SideRail));
    expect(rail.currentIndex, 1);
  });
}
