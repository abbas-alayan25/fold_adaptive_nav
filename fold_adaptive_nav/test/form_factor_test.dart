import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fold_adaptive_nav/fold_adaptive_nav.dart';

import 'helpers.dart';

void main() {
  // (name, size in pt, expected without a fold reading, expected when closed)
  const matrix = [
    ('iPhone SE', Size(375, 667), FormFactor.phone, FormFactor.cover),
    ('iPhone 16', Size(393, 852), FormFactor.phone, FormFactor.cover),
    (
      'iPhone 16 on its side',
      Size(852, 393),
      FormFactor.phone,
      FormFactor.cover
    ),
    ('iPhone 16 Pro Max', Size(440, 956), FormFactor.phone, FormFactor.cover),
    ('iPhone Duo closed', Size(466, 678), FormFactor.cover, FormFactor.cover),
    ('iPhone Duo open', Size(669, 951), FormFactor.tablet, FormFactor.tablet),
    (
      'iPhone Duo open, on its side',
      Size(951, 669),
      FormFactor.tablet,
      FormFactor.tablet
    ),
    ('iPad mini', Size(744, 1133), FormFactor.tablet, FormFactor.tablet),
    (
      'iPad mini landscape',
      Size(1133, 744),
      FormFactor.tablet,
      FormFactor.tablet
    ),
    (
      'iPad Pro 13" landscape',
      Size(1366, 1024),
      FormFactor.tablet,
      FormFactor.tablet
    ),
    (
      'iPad Split View 1/3',
      Size(320, 1024),
      FormFactor.phone,
      FormFactor.cover
    ),
    ('Pixel Fold outer', Size(412, 869), FormFactor.phone, FormFactor.cover),
    ('Pixel Fold inner', Size(841, 701), FormFactor.tablet, FormFactor.tablet),
    ('Galaxy Z Fold outer', Size(344, 882), FormFactor.phone, FormFactor.cover),
  ];

  for (final (name, size, plain, closed) in matrix) {
    test('$name ${size.width}×${size.height} → ${plain.name}', () {
      expect(
          resolveFormFactor(window: size, fold: FoldState.unsupported), plain);
    });
    test('$name with posture closed → ${closed.name}', () {
      expect(resolveFormFactor(window: size, fold: closedFoldable), closed);
    });
  }

  test('a closed posture on a device that is not a foldable is ignored', () {
    final notFoldable = closedFoldable.copyWith(isFoldable: false);
    expect(
      resolveFormFactor(window: const Size(412, 869), fold: notFoldable),
      FormFactor.phone,
    );
  });

  test('breakpoints are configurable', () {
    const config = FoldAdaptiveConfig(mediumBreakpoint: 700);
    expect(
      resolveFormFactor(
        window: const Size(669, 951),
        fold: FoldState.unsupported,
        config: config,
      ),
      FormFactor.cover, // 669 is now below tablet, and squat (1.42)
    );
  });

  group('orientationsFor', () {
    const config = FoldAdaptiveConfig();
    test('closed foldable → cover orientations', () {
      expect(orientationsFor(closedFoldable, FormFactor.cover, config),
          config.coverOrientations);
    });
    test('open foldable → all, even in a phone-sized window', () {
      expect(orientationsFor(openFoldable, FormFactor.phone, config),
          DeviceOrientation.values);
    });
    test('unknown posture falls back to the window', () {
      final unknown = openFoldable.copyWith(posture: HingePosture.unknown);
      expect(orientationsFor(unknown, FormFactor.phone, config),
          [DeviceOrientation.portraitUp]);
      expect(orientationsFor(unknown, FormFactor.tablet, config),
          DeviceOrientation.values);
    });
    test('phones unlock when lockPhonesToPortrait is off', () {
      expect(
        orientationsFor(FoldState.unsupported, FormFactor.phone,
            const FoldAdaptiveConfig(lockPhonesToPortrait: false)),
        DeviceOrientation.values,
      );
    });
  });
}
