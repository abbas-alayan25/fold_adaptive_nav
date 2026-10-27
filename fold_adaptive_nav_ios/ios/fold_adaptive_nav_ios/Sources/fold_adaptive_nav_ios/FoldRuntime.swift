import ObjectiveC
import UIKit

/// One reading of the hinge.
struct HingeReading: Equatable {
  /// "closed", "partiallyOpen", "fullyOpen" or "unknown".
  let posture: String
  /// 0 = shut, 180 = flat.
  let degrees: Double

  /// `status` is `UIHinge.Status`'s raw value, `radians` is `UIHinge.angle`.
  init(status: Int, radians: Double) {
    switch status {
    case 1: posture = "closed"
    case 2: posture = "partiallyOpen"
    case 3: posture = "fullyOpen"
    default: posture = "unknown"
    }
    degrees = min(max(radians * 180 / .pi, 0), 180)
  }
}

/// One `UIViewReservedRegion`, already reduced to what Dart needs.
struct RegionReading: Equatable {
  let frame: CGRect
  let isActive: Bool
}

/// Resolves the iOS 27.1 fold APIs (`UIHingeInteraction`,
/// `reservedRegionsOfKind:options:`) through the Objective-C runtime, so the
/// plugin builds with any Xcode that Flutter supports. Every lookup fails soft:
/// a missing class or selector reads as "not a foldable" instead of crashing.
///
/// Define `FOLD_NATIVE_API` to use the typed Swift API instead (needs the
/// iOS 27.1 SDK).
enum FoldRuntime {
  // MARK: Hinge

  /// Creates a `UIHingeInteraction` whose handler reports `nil` while the
  /// device has no hinge. Returns `nil` where the class doesn't exist.
  static func makeHingeInteraction(
    onUpdate: @escaping (HingeReading?) -> Void
  ) -> UIInteraction? {
    #if FOLD_NATIVE_API
      if #available(iOS 27.1, *) {
        return UIHingeInteraction { _, update in
          onUpdate(update.hinge.map {
            HingeReading(status: $0.status.rawValue, radians: Double($0.angle))
          })
        }
      }
      return nil
    #else
      return makeHingeInteractionDynamically(onUpdate: onUpdate)
    #endif
  }

  static func makeHingeInteractionDynamically(
    onUpdate: @escaping (HingeReading?) -> Void
  ) -> UIInteraction? {
    // Adding an object that doesn't conform to UIInteraction crashes.
    guard let cls = NSClassFromString("UIHingeInteraction"),
      let interactionProtocol = objc_getProtocol("UIInteraction"),
      class_conformsToProtocol(cls, interactionProtocol)
    else { return nil }

    let allocSel = NSSelectorFromString("alloc")
    let initSel = NSSelectorFromString("initWithUpdateHandler:")
    guard class_getInstanceMethod(cls, initSel) != nil,
      let metaclass = object_getClass(cls),
      let allocImp = class_getMethodImplementation(metaclass, allocSel),
      let initImp = class_getMethodImplementation(cls, initSel)
    else { return nil }

    typealias Handler = @convention(block) (AnyObject, AnyObject) -> Void
    typealias AllocFn = @convention(c) (AnyClass, Selector) -> UnsafeMutableRawPointer?
    typealias InitFn = @convention(c) (UnsafeMutableRawPointer, Selector, Handler)
      -> UnsafeMutableRawPointer?

    let handler: Handler = { _, update in
      onUpdate(hingeReading(fromUpdate: update as? NSObject))
    }
    // alloc returns +1; init consumes it and returns +1.
    guard let allocated = unsafeBitCast(allocImp, to: AllocFn.self)(cls, allocSel),
      let initialised = unsafeBitCast(initImp, to: InitFn.self)(allocated, initSel, handler)
    else { return nil }
    return Unmanaged<AnyObject>.fromOpaque(initialised).takeRetainedValue() as? UIInteraction
  }

  /// Reads `update.hinge.status` and `update.hinge.angle`, gating every read
  /// on `responds(to:)`.
  static func hingeReading(fromUpdate update: NSObject?) -> HingeReading? {
    guard let update, update.responds(to: NSSelectorFromString("hinge")),
      let hinge = update.value(forKey: "hinge") as? NSObject,
      hinge.responds(to: NSSelectorFromString("status")),
      hinge.responds(to: NSSelectorFromString("angle")),
      let status = hinge.value(forKey: "status") as? NSNumber,
      let angle = hinge.value(forKey: "angle") as? NSNumber
    else { return nil }
    return HingeReading(status: status.intValue, radians: angle.doubleValue)
  }

  // MARK: Reserved regions

  enum RegionKind: String {
    case division = "divisionRegionKind"
    case occlusion = "occlusionRegionKind"
  }

  /// `view.reservedRegions(kind:options:)`; empty where unavailable.
  static func reservedRegions(
    of kind: RegionKind, in view: UIView, includeInactive: Bool
  ) -> [RegionReading] {
    #if FOLD_NATIVE_API
      if #available(iOS 27.1, *) {
        let nativeKind: UIView.ReservedRegion.Kind = kind == .division ? .division : .occlusion
        return view.reservedRegions(
          kind: nativeKind, options: includeInactive ? .includeInactive : []
        ).map { RegionReading(frame: $0.frame, isActive: $0.isActive) }
      }
      return []
    #else
      return reservedRegionsDynamically(of: kind, in: view, includeInactive: includeInactive)
    #endif
  }

  static func reservedRegionsDynamically(
    of kind: RegionKind, in view: UIView, includeInactive: Bool
  ) -> [RegionReading] {
    let querySel = NSSelectorFromString("reservedRegionsOfKind:options:")
    guard view.responds(to: querySel),
      let kindObject = regionKind(kind),
      let queryImp = class_getMethodImplementation(type(of: view), querySel)
    else { return [] }

    typealias QueryFn = @convention(c) (UIView, Selector, AnyObject, UInt)
      -> UnsafeMutableRawPointer?
    let includeInactiveOption: UInt = 1 << 0
    guard
      let raw = unsafeBitCast(queryImp, to: QueryFn.self)(
        view, querySel, kindObject, includeInactive ? includeInactiveOption : 0)
    else { return [] }
    let regions = Unmanaged<NSArray>.fromOpaque(raw).takeUnretainedValue()

    let frameSel = NSSelectorFromString("frame")
    let activeSel = NSSelectorFromString("isActive")
    return regions.compactMap { element in
      guard let region = element as? NSObject,
        region.responds(to: frameSel), region.responds(to: activeSel),
        let frame = (region.value(forKey: "frame") as? NSValue)?.cgRectValue,
        let active = region.value(forKey: "active") as? NSNumber
      else { return nil }
      return RegionReading(frame: frame, isActive: active.boolValue)
    }
  }

  /// `+[UIViewReservedRegionKind divisionRegionKind]` and friends.
  private static func regionKind(_ kind: RegionKind) -> AnyObject? {
    let sel = NSSelectorFromString(kind.rawValue)
    guard let cls = NSClassFromString("UIViewReservedRegionKind"),
      class_getClassMethod(cls, sel) != nil,
      let metaclass = object_getClass(cls),
      let imp = class_getMethodImplementation(metaclass, sel)
    else { return nil }
    typealias KindFn = @convention(c) (AnyClass, Selector) -> UnsafeMutableRawPointer?
    guard let raw = unsafeBitCast(imp, to: KindFn.self)(cls, sel) else { return nil }
    return Unmanaged<AnyObject>.fromOpaque(raw).takeUnretainedValue()
  }
}
