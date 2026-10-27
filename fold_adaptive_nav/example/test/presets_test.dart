import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fold_adaptive_nav/fold_adaptive_nav.dart';
import 'package:fold_adaptive_nav_example/main.dart';
import 'package:fold_adaptive_nav_example/settings_page.dart';

/// Runs the example on every device preset and opens each tab, the way an
/// app can check its own layouts without the devices.
void main() {
  const tabs = [
    Icons.inbox_outlined,
    Icons.swap_horiz_outlined,
    Icons.play_circle_outline,
  ];

  for (final preset in FoldDevicePreset.all) {
    testWidgets('example on ${preset.name}', (tester) async {
      await tester.pumpWidget(FoldPreview(
        preset: preset,
        child: MaterialApp(
          home: HomeShell(
            settings: const ExampleSettings(),
            onSettingsChanged: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('This device'), findsOneWidget);

      for (final icon in tabs) {
        await tester.tap(find.byIcon(icon).first);
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('More opens the tabs that do not fit the bar', (tester) async {
    await tester.pumpWidget(FoldPreview(
      preset: FoldDevicePreset.phone,
      child: MaterialApp(
        home: HomeShell(
          settings: const ExampleSettings(),
          onSettingsChanged: (_) {},
        ),
      ),
    ));
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gallery'));
    await tester.pumpAndSettle();
    expect(find.text('Gallery'), findsWidgets);
    expect(find.text('2 columns'), findsOneWidget);
  });
}
