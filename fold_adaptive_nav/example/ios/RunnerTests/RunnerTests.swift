import Flutter
import UIKit
import XCTest

@testable import fold_adaptive_nav_ios

/// The plugin's logic that doesn't need an iPhone Duo: on the simulator the
/// fold APIs are missing, and every lookup must fail soft.
class RunnerTests: XCTestCase {

  // MARK: HingeReading

  func testHingeStatusMapsToPosture() {
    XCTAssertEqual(HingeReading(status: 1, radians: 0).posture, "closed")
    XCTAssertEqual(HingeReading(status: 2, radians: 1).posture, "partiallyOpen")
    XCTAssertEqual(HingeReading(status: 3, radians: .pi).posture, "fullyOpen")
    XCTAssertEqual(HingeReading(status: 0, radians: 0).posture, "unknown")
    XCTAssertEqual(HingeReading(status: 99, radians: 0).posture, "unknown")
  }

  func testHingeAngleIsDegreesClampedToZeroTo180() {
    XCTAssertEqual(HingeReading(status: 2, radians: .pi / 2).degrees, 90, accuracy: 1e-9)
    XCTAssertEqual(HingeReading(status: 3, radians: 4).degrees, 180)
    XCTAssertEqual(HingeReading(status: 1, radians: -0.2).degrees, 0)
  }

  // MARK: Reading UIHingeInteraction updates through the runtime

  func testReadsHingeFromAnUpdateObject() {
    let update = FakeUpdate(hinge: FakeHinge(status: 2, angle: .pi / 3))
    let reading = FoldRuntime.hingeReading(fromUpdate: update)
    XCTAssertEqual(reading?.posture, "partiallyOpen")
    XCTAssertEqual(reading?.degrees ?? 0, 60, accuracy: 1e-9)
  }

  func testUpdateWithoutAHingeReadsAsNil() {
    XCTAssertNil(FoldRuntime.hingeReading(fromUpdate: nil))
    XCTAssertNil(FoldRuntime.hingeReading(fromUpdate: NSObject()))
    XCTAssertNil(FoldRuntime.hingeReading(fromUpdate: FakeUpdate(hinge: NSObject())))
  }

  // MARK: Failing soft without the iOS 27.1 APIs

  func testRegionsOfAPlainViewAreEmpty() {
    let view = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
    XCTAssertTrue(
      FoldRuntime.reservedRegions(of: .division, in: view, includeInactive: true).isEmpty)
    XCTAssertTrue(
      FoldRuntime.reservedRegions(of: .occlusion, in: view, includeInactive: false).isEmpty)
  }

  // MARK: FoldMonitor's wire map (read by FoldStateCodec.decode in Dart)

  func testSnapshotWithoutAViewIsUnsupported() {
    let state = FoldMonitor().snapshot()
    XCTAssertEqual(state["v"] as? Int, 1)
    XCTAssertEqual(state["isFoldable"] as? Bool, false)
    XCTAssertEqual(state["posture"] as? String, "unknown")
    XCTAssertEqual((state["regions"] as? [Any])?.count, 0)
    XCTAssertEqual(state["horizontalSizeClass"] as? String, "unspecified")
    XCTAssertTrue(state["hingeAngle"] is NSNull)
  }

  func testAttachingAddsAProbeAndPublishesOnce() {
    let view = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
    let monitor = FoldMonitor()
    var published: [[String: Any]] = []
    monitor.onState = { published.append($0) }

    monitor.attach(to: view)
    XCTAssertEqual(view.subviews.filter { $0 is LayoutProbe }.count, 1)
    XCTAssertEqual(published.count, 1)
    XCTAssertEqual(published.first?["isFoldable"] as? Bool, false)

    // Nothing changed: a layout pass publishes nothing new.
    view.setNeedsLayout()
    view.layoutIfNeeded()
    XCTAssertEqual(published.count, 1)

    monitor.detach()
    XCTAssertTrue(view.subviews.filter { $0 is LayoutProbe }.isEmpty)
  }

  func testLayoutProbeNeverTakesTouches() {
    let probe = LayoutProbe(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    XCTAssertNil(probe.hitTest(CGPoint(x: 50, y: 50), with: nil))
    XCTAssertFalse(probe.isUserInteractionEnabled)
    XCTAssertFalse(probe.isAccessibilityElement)
  }
}

/// Stands in for `UIHinge`, read through key-value coding as the plugin does.
private final class FakeHinge: NSObject {
  @objc let status: NSNumber
  @objc let angle: NSNumber

  init(status: Int, angle: Double) {
    self.status = NSNumber(value: status)
    self.angle = NSNumber(value: angle)
  }
}

/// Stands in for the `UIHingeInteraction` update.
private final class FakeUpdate: NSObject {
  @objc let hinge: NSObject

  init(hinge: NSObject) { self.hinge = hinge }
}
