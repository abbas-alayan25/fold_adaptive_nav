import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fold_adaptive_nav/fold_adaptive_nav.dart';

import 'helpers.dart';

void main() {
  const portrait = ['DeviceOrientation.portraitUp'];
  final all = [for (final o in DeviceOrientation.values) o.toString()];

  testWidgets('orientations follow the posture: closed → open → closed',
      (tester) async {
    final calls = captureOrientations(tester);
    setWindowSize(tester, const Size(466, 678));
    final controller = await pumpScoped(tester, const SizedBox());

    // Nothing is locked before the first reading.
    expect(calls, isEmpty);

    controller.add(closedFoldable);
    await tester.pump();
    expect(calls, [portrait]);

    setWindowSize(tester, const Size(669, 951));
    controller.add(openFoldable);
    await tester.pump();
    expect(calls, [portrait, all]);

    setWindowSize(tester, const Size(466, 678));
    controller.add(closedFoldable);
    await tester.pump();
    expect(calls, [portrait, all, portrait]);

    // The same reading again doesn't call the platform again.
    controller.add(closedFoldable.copyWith(hingeAngle: () => 3));
    await tester.pump();
    expect(calls, hasLength(3));
  });

  testWidgets('manageOrientations: false leaves orientations alone',
      (tester) async {
    final calls = captureOrientations(tester);
    await pumpScoped(
      tester,
      const SizedBox(),
      state: closedFoldable,
      config: const FoldAdaptiveConfig(manageOrientations: false),
    );
    expect(calls, isEmpty);
  });

  testWidgets('FoldMediaQuery publishes the state and form factor',
      (tester) async {
    setWindowSize(tester, const Size(412, 869));
    late FormFactor formFactor;
    late HingePosture posture;
    final controller = await pumpScoped(
      tester,
      Builder(builder: (context) {
        formFactor = context.formFactor;
        posture = FoldMediaQuery.postureOf(context);
        return const SizedBox();
      }),
    );
    expect(formFactor, FormFactor.phone);
    expect(posture, HingePosture.unknown);

    controller.add(closedFoldable);
    await tester.pump();
    expect(formFactor, FormFactor.cover);
    expect(posture, HingePosture.closed);
  });

  testWidgets('a posture-only reader does not rebuild for a new angle',
      (tester) async {
    var builds = 0;
    final controller = await pumpScoped(
      tester,
      Builder(builder: (context) {
        FoldMediaQuery.postureOf(context);
        builds++;
        return const SizedBox();
      }),
      state: closedFoldable,
    );
    final before = builds;
    controller.add(closedFoldable.copyWith(hingeAngle: () => 12));
    await tester.pump();
    expect(builds, before);
  });

  testWidgets('FormFactorOverride pins the form factor', (tester) async {
    late FormFactor formFactor;
    await pumpScoped(
      tester,
      FormFactorOverride(
        formFactor: FormFactor.cover,
        child: Builder(builder: (context) {
          formFactor = context.formFactor;
          return const SizedBox();
        }),
      ),
    );
    expect(formFactor, FormFactor.cover);
  });

  group('display feature bridge', () {
    const halfOpen = FoldState(
      isFoldable: true,
      posture: HingePosture.partiallyOpen,
      hingeAngle: 100,
      regions: [
        FoldRegion(
          kind: RegionKind.fold,
          bounds: Rect.fromLTWH(332, 0, 4, 951),
          isActive: true,
        ),
        FoldRegion(
          kind: RegionKind.cameraOcclusion,
          bounds: Rect.fromLTWH(600, 10, 40, 40),
          isActive: true,
        ),
      ],
      horizontalSizeClass: SizeClass.regular,
      verticalSizeClass: SizeClass.regular,
    );

    Future<List<DisplayFeature>> featuresWith(
      WidgetTester tester,
      DisplayFeatureBridge bridge,
      FoldState state,
    ) async {
      late List<DisplayFeature> features;
      await tester.pumpWidget(FoldScope(
        bridge: bridge,
        debugState: Stream.value(state),
        config: const FoldAdaptiveConfig(manageOrientations: false),
        child: Builder(builder: (context) {
          features = MediaQuery.displayFeaturesOf(context);
          return const SizedBox();
        }),
      ));
      await tester.pump();
      return features;
    }

    testWidgets('none publishes nothing', (tester) async {
      expect(await featuresWith(tester, DisplayFeatureBridge.none, halfOpen),
          isEmpty);
    });

    testWidgets('cutoutsOnly publishes the camera only', (tester) async {
      final features =
          await featuresWith(tester, DisplayFeatureBridge.cutoutsOnly, halfOpen);
      expect(features.map((f) => f.type), [DisplayFeatureType.cutout]);
    });

    testWidgets('full adds the fold only while partly open', (tester) async {
      var features =
          await featuresWith(tester, DisplayFeatureBridge.full, halfOpen);
      expect(features.map((f) => f.type),
          containsAll([DisplayFeatureType.cutout, DisplayFeatureType.fold]));

      features = await featuresWith(tester, DisplayFeatureBridge.full,
          halfOpen.copyWith(posture: HingePosture.fullyOpen));
      expect(features.map((f) => f.type), [DisplayFeatureType.cutout]);
    });
  });
}
