import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fold_adaptive_nav_platform_interface/fold_adaptive_nav_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  Future<void> sendAngle(double degrees) => messenger.handlePlatformMessage(
        MethodChannelFold.angleEvents.name,
        const StandardMethodCodec().encodeSuccessEnvelope(degrees),
        (_) {},
      );

  test('a late listener gets the latest hinge angle straight away', () async {
    messenger.setMockStreamHandler(
      MethodChannelFold.angleEvents,
      MockStreamHandler.inline(onListen: (_, __) {}),
    );
    final platform = MethodChannelFold();

    final first = <double>[];
    final sub = platform.hingeAngle.listen(first.add);
    await sendAngle(42);
    await pumpEventQueue();
    expect(first, [42]);

    // E.g. a widget rebuilt after the layout switched on fold.
    final late = <double>[];
    final lateSub = platform.hingeAngle.listen(late.add);
    await pumpEventQueue();
    expect(late, [42]);

    await sendAngle(90);
    await pumpEventQueue();
    expect(first, [42, 90]);
    expect(late, [42, 90]);

    await sub.cancel();
    await lateSub.cancel();
  });
}
