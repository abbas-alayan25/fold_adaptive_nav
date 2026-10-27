import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fold_adaptive_nav_platform_interface/fold_adaptive_nav_platform_interface.dart';

void main() {
  const open = FoldState(
    isFoldable: true,
    posture: HingePosture.partiallyOpen,
    hingeAngle: 110,
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

  test('round-trips through the wire format', () {
    final wire = FoldStateCodec.encode(open);
    expect(wire['v'], 1);
    expect(FoldStateCodec.decode(wire), open);
  });

  test('ignores unknown keys and maps unknown enums to unknown', () {
    final state = FoldStateCodec.decode({
      'v': 2,
      'isFoldable': true,
      'posture': 'tent',
      'horizontalSizeClass': 'huge',
      'somethingNew': [1, 2, 3],
      'regions': [
        {'kind': 'hologram', 'left': 0, 'top': 0, 'width': 1, 'height': 1},
        {'kind': 'fold', 'left': 'x'},
        {'kind': 'fold', 'left': 1, 'top': 2, 'width': 3, 'height': 4},
      ],
    });
    expect(state.isFoldable, isTrue);
    expect(state.posture, HingePosture.unknown);
    expect(state.horizontalSizeClass, SizeClass.unspecified);
    expect(state.regions, [
      const FoldRegion(
        kind: RegionKind.fold,
        bounds: Rect.fromLTWH(1, 2, 3, 4),
        isActive: false,
      ),
    ]);
  });

  test('anything that is not a map decodes as unsupported', () {
    expect(FoldStateCodec.decode(null), FoldState.unsupported);
    expect(FoldStateCodec.decode('closed'), FoldState.unsupported);
  });

  test('the default platform reports unsupported', () async {
    expect(await FoldPlatform.instance.snapshot(), FoldState.unsupported);
  });
}
