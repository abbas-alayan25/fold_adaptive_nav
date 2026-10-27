import 'dart:ui' show Rect;

import 'models.dart';

/// Converts [FoldState] to and from the maps sent over the platform channels.
///
/// Every map carries `"v": 1`. Decoding is lenient: unknown keys are ignored,
/// unknown enum strings map to the `unknown`/`unspecified` value and malformed
/// regions are dropped, so a newer native side never crashes an older Dart
/// side.
abstract final class FoldStateCodec {
  static const int version = 1;

  static FoldState decode(Object? message) {
    if (message is! Map) return FoldState.unsupported;
    return FoldState(
      isFoldable: message['isFoldable'] == true,
      posture: _posture(message['posture']),
      hingeAngle: _double(message['hingeAngle']),
      regions: [
        if (message['regions'] case final List regions)
          for (final r in regions)
            if (_region(r) case final FoldRegion region) region,
      ],
      horizontalSizeClass: _sizeClass(message['horizontalSizeClass']),
      verticalSizeClass: _sizeClass(message['verticalSizeClass']),
    );
  }

  static Map<String, Object?> encode(FoldState state) => {
        'v': version,
        'isFoldable': state.isFoldable,
        'posture': state.posture.name,
        'hingeAngle': state.hingeAngle,
        'regions': [
          for (final r in state.regions)
            {
              'kind': r.kind.name,
              'left': r.bounds.left,
              'top': r.bounds.top,
              'width': r.bounds.width,
              'height': r.bounds.height,
              'isActive': r.isActive,
            },
        ],
        'horizontalSizeClass': state.horizontalSizeClass.name,
        'verticalSizeClass': state.verticalSizeClass.name,
      };

  static HingePosture _posture(Object? value) => switch (value) {
        'closed' => HingePosture.closed,
        'partiallyOpen' => HingePosture.partiallyOpen,
        'fullyOpen' => HingePosture.fullyOpen,
        _ => HingePosture.unknown,
      };

  static SizeClass _sizeClass(Object? value) => switch (value) {
        'compact' => SizeClass.compact,
        'regular' => SizeClass.regular,
        _ => SizeClass.unspecified,
      };

  static FoldRegion? _region(Object? value) {
    if (value is! Map) return null;
    final kind = switch (value['kind']) {
      'fold' => RegionKind.fold,
      'cameraOcclusion' => RegionKind.cameraOcclusion,
      _ => null,
    };
    final left = _double(value['left']);
    final top = _double(value['top']);
    final width = _double(value['width']);
    final height = _double(value['height']);
    if (kind == null ||
        left == null ||
        top == null ||
        width == null ||
        height == null) {
      return null;
    }
    return FoldRegion(
      kind: kind,
      bounds: Rect.fromLTWH(left, top, width, height),
      isActive: value['isActive'] == true,
    );
  }

  static double? _double(Object? value) =>
      value is num && value.isFinite ? value.toDouble() : null;
}
