import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fold_adaptive_nav/fold_adaptive_nav.dart';

const closedFoldable = FoldState(
  isFoldable: true,
  posture: HingePosture.closed,
  hingeAngle: 0,
  regions: [],
  horizontalSizeClass: SizeClass.compact,
  verticalSizeClass: SizeClass.regular,
);

const openFoldable = FoldState(
  isFoldable: true,
  posture: HingePosture.fullyOpen,
  hingeAngle: 180,
  regions: [],
  horizontalSizeClass: SizeClass.regular,
  verticalSizeClass: SizeClass.regular,
);

/// Sets the test window to [size] logical pixels at 3×.
void setWindowSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = size * 3;
  addTearDown(tester.view.reset);
}

/// Records every `SystemChrome.setPreferredOrientations` call.
List<List<String>> captureOrientations(WidgetTester tester) {
  final calls = <List<String>>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'SystemChrome.setPreferredOrientations') {
        calls.add((call.arguments as List).cast<String>());
      }
      return null;
    },
  );
  addTearDown(() => tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null));
  return calls;
}

/// Pumps [home] below a [FoldScope] fed from a synchronous controller.
Future<StreamController<FoldState>> pumpScoped(
  WidgetTester tester,
  Widget home, {
  FoldState? state,
  FoldAdaptiveConfig config = const FoldAdaptiveConfig(),
  TextDirection direction = TextDirection.ltr,
}) async {
  final controller = StreamController<FoldState>(sync: true);
  addTearDown(controller.close);
  await tester.pumpWidget(FoldScope(
    config: config,
    debugState: controller.stream,
    child: MaterialApp(
      builder: (context, child) =>
          Directionality(textDirection: direction, child: child!),
      home: home,
    ),
  ));
  if (state != null) {
    controller.add(state);
    await tester.pumpAndSettle();
  }
  return controller;
}
