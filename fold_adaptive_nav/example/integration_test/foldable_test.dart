// Runs on a real device or emulator, through the native plugin:
//
//   flutter test integration_test
//
// CI runs it on the Android emulator's Pixel Fold profile, where the plugin
// must report a foldable and the layout must follow its posture.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fold_adaptive_nav/fold_adaptive_nav.dart';
import 'package:fold_adaptive_nav_example/main.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the native plugin reports the device and the layout follows',
      (tester) async {
    await tester.pumpWidget(const ExampleApp());
    // The first reading comes over the platform channel.
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final context = tester.element(find.byType(HomeShell));
    final state = FoldMediaQuery.stateOf(context);
    final formFactor = context.formFactor;
    debugPrint('fold_adaptive_nav: $state, $formFactor, '
        '${MediaQuery.sizeOf(context)}');

    // Set by CI for a foldable emulator; anywhere else, only consistency is
    // checked.
    const expectFoldable = bool.fromEnvironment('EXPECT_FOLDABLE');
    if (expectFoldable) {
      expect(state.isFoldable, isTrue);
      expect(state.posture, isNot(HingePosture.unknown));
    }

    // The navigation matches the form factor the package decided.
    switch (formFactor) {
      case FormFactor.cover:
        expect(find.byType(SideRail), findsOneWidget);
      case FormFactor.phone:
        expect(find.byType(NavigationBar), findsOneWidget);
      case FormFactor.tablet:
        expect(
          find.byType(NavigationBar).evaluate().length +
              find.byType(NavigationRail).evaluate().length +
              find.byType(SideRail).evaluate().length,
          1,
        );
    }

    // Opening a tab works through whichever navigation is showing.
    await tester.tap(find.byIcon(Icons.inbox_outlined).first);
    await tester.pumpAndSettle();
    expect(find.text('Inbox'), findsWidgets);
  });
}
