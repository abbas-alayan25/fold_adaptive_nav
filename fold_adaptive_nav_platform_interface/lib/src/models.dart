import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';

/// Position of the hinge on a foldable device.
enum HingePosture {
  /// Folded shut; the app runs on the cover (outer) display.
  closed,

  /// Somewhere between shut and flat (book or tent posture).
  partiallyOpen,

  /// Open as far as the device allows, usually flat.
  fullyOpen,

  /// No reading yet, or not a foldable.
  unknown,
}

/// UIKit's size classes. Always [SizeClass.unspecified] on Android.
enum SizeClass { compact, regular, unspecified }

/// What a [FoldRegion] marks on the display.
enum RegionKind {
  /// The fold or hinge between two halves of the display.
  fold,

  /// A camera or sensor housing that covers part of the display.
  cameraOcclusion,
}

/// A part of the display the app should keep content away from.
@immutable
class FoldRegion {
  const FoldRegion({
    required this.kind,
    required this.bounds,
    required this.isActive,
  });

  final RegionKind kind;

  /// Logical pixels, in the Flutter view's coordinate space.
  final Rect bounds;

  /// A fold is active only while the device is partly open.
  final bool isActive;

  @override
  bool operator ==(Object other) =>
      other is FoldRegion &&
      other.kind == kind &&
      other.bounds == bounds &&
      other.isActive == isActive;

  @override
  int get hashCode => Object.hash(kind, bounds, isActive);

  @override
  String toString() =>
      'FoldRegion(${kind.name}, $bounds, ${isActive ? 'active' : 'inactive'})';
}

/// Everything the native side knows about the device's fold.
@immutable
class FoldState {
  const FoldState({
    required this.isFoldable,
    required this.posture,
    required this.hingeAngle,
    required this.regions,
    required this.horizontalSizeClass,
    required this.verticalSizeClass,
  });

  /// The answer on platforms without a native implementation (web, desktop),
  /// and before the first reading arrives.
  static const unsupported = FoldState(
    isFoldable: false,
    posture: HingePosture.unknown,
    hingeAngle: null,
    regions: [],
    horizontalSizeClass: SizeClass.unspecified,
    verticalSizeClass: SizeClass.unspecified,
  );

  /// The hardware has a hinge.
  final bool isFoldable;

  final HingePosture posture;

  /// Degrees, 0 = shut, 180 = flat; null if unknown.
  ///
  /// Only a snapshot taken with the rest of the state. Listen to
  /// `FoldPlatform.instance.hingeAngle` for a per-frame value.
  final double? hingeAngle;

  final List<FoldRegion> regions;

  /// iOS only; [SizeClass.unspecified] on Android.
  final SizeClass horizontalSizeClass;

  /// iOS only; [SizeClass.unspecified] on Android.
  final SizeClass verticalSizeClass;

  /// The fold regions, active or not.
  Iterable<FoldRegion> get folds =>
      regions.where((r) => r.kind == RegionKind.fold);

  /// The camera and sensor housings.
  Iterable<FoldRegion> get cameraOcclusions =>
      regions.where((r) => r.kind == RegionKind.cameraOcclusion);

  FoldState copyWith({
    bool? isFoldable,
    HingePosture? posture,
    ValueGetter<double?>? hingeAngle,
    List<FoldRegion>? regions,
    SizeClass? horizontalSizeClass,
    SizeClass? verticalSizeClass,
  }) {
    return FoldState(
      isFoldable: isFoldable ?? this.isFoldable,
      posture: posture ?? this.posture,
      hingeAngle: hingeAngle != null ? hingeAngle() : this.hingeAngle,
      regions: regions ?? this.regions,
      horizontalSizeClass: horizontalSizeClass ?? this.horizontalSizeClass,
      verticalSizeClass: verticalSizeClass ?? this.verticalSizeClass,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FoldState &&
      other.isFoldable == isFoldable &&
      other.posture == posture &&
      other.hingeAngle == hingeAngle &&
      listEquals(other.regions, regions) &&
      other.horizontalSizeClass == horizontalSizeClass &&
      other.verticalSizeClass == verticalSizeClass;

  @override
  int get hashCode => Object.hash(
        isFoldable,
        posture,
        hingeAngle,
        Object.hashAll(regions),
        horizontalSizeClass,
        verticalSizeClass,
      );

  @override
  String toString() => 'FoldState(isFoldable: $isFoldable, '
      'posture: ${posture.name}, hingeAngle: $hingeAngle, regions: $regions, '
      'size classes: ${horizontalSizeClass.name}/${verticalSizeClass.name})';
}
