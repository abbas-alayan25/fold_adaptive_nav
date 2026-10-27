import UIKit

/// Watches one Flutter view: hinge, reserved regions and size classes.
/// Publishes a full state map whenever any of them changes.
final class FoldMonitor {
  /// Full `FoldState` maps, only when something other than the angle changed.
  var onState: (([String: Any]) -> Void)?
  /// Raw hinge angle in degrees, on every hinge update.
  var onAngle: ((Double) -> Void)?

  private weak var view: UIView?
  private var probe: LayoutProbe?
  private var interaction: UIInteraction?
  private var hinge: HingeReading?
  private var hasSeenHinge = false
  private var lastPublished: NSDictionary?

  var latestAngle: Double? { hinge?.degrees }

  func attach(to view: UIView) {
    guard self.view !== view else { return }
    detach()
    self.view = view

    // A transparent child that follows the view's size; its layout and trait
    // callbacks stand in for viewDidLayoutSubviews on a controller we don't own.
    let probe = LayoutProbe(frame: view.bounds)
    probe.onChange = { [weak self] in self?.publishIfChanged() }
    view.insertSubview(probe, at: 0)
    self.probe = probe

    if let interaction = FoldRuntime.makeHingeInteraction(onUpdate: { [weak self] reading in
      self?.hingeDidUpdate(reading)
    }) {
      view.addInteraction(interaction)
      self.interaction = interaction
    }
    publishIfChanged()
  }

  func detach() {
    if let interaction { view?.removeInteraction(interaction) }
    probe?.removeFromSuperview()
    interaction = nil
    probe = nil
    view = nil
  }

  /// The current state as a wire map.
  func snapshot() -> [String: Any] {
    var state = stateWithoutAngle()
    state["hingeAngle"] = hinge?.degrees ?? NSNull()
    return state
  }

  private func hingeDidUpdate(_ reading: HingeReading?) {
    if reading != nil { hasSeenHinge = true }
    hinge = reading
    if let degrees = reading?.degrees { onAngle?(degrees) }
    // Regions change with the hinge, without a layout pass.
    publishIfChanged()
  }

  private func publishIfChanged() {
    // The angle moves every frame while folding; it isn't a reason to publish.
    let comparable = stateWithoutAngle() as NSDictionary
    guard comparable != lastPublished else { return }
    lastPublished = comparable
    onState?(snapshot())
  }

  private func stateWithoutAngle() -> [String: Any] {
    let posture = hinge?.posture ?? "unknown"
    var regions: [[String: Any]] = []
    if let view {
      // The fold is inactive while flat, but its position is still useful.
      for fold in FoldRuntime.reservedRegions(of: .division, in: view, includeInactive: true) {
        // isActive lags the hinge; trust it only while partly open.
        regions.append(
          Self.encode(fold, kind: "fold", isActive: fold.isActive && posture == "partiallyOpen"))
      }
      for camera in FoldRuntime.reservedRegions(of: .occlusion, in: view, includeInactive: false) {
        regions.append(Self.encode(camera, kind: "cameraOcclusion", isActive: camera.isActive))
      }
    }
    let traits = view?.traitCollection
    return [
      "v": 1,
      "isFoldable": hasSeenHinge,
      "posture": posture,
      "regions": regions,
      "horizontalSizeClass": Self.encode(traits?.horizontalSizeClass),
      "verticalSizeClass": Self.encode(traits?.verticalSizeClass),
    ]
  }

  private static func encode(_ region: RegionReading, kind: String, isActive: Bool)
    -> [String: Any]
  {
    [
      "kind": kind,
      "left": Double(region.frame.minX),
      "top": Double(region.frame.minY),
      "width": Double(region.frame.width),
      "height": Double(region.frame.height),
      "isActive": isActive,
    ]
  }

  private static func encode(_ sizeClass: UIUserInterfaceSizeClass?) -> String {
    switch sizeClass {
    case .compact: return "compact"
    case .regular: return "regular"
    default: return "unspecified"
    }
  }
}

/// Invisible, untouchable view that reports layout and size-class changes.
final class LayoutProbe: UIView {
  var onChange: (() -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    autoresizingMask = [.flexibleWidth, .flexibleHeight]
    isUserInteractionEnabled = false
    isAccessibilityElement = false
    backgroundColor = .clear
    if #available(iOS 17.0, *) {
      registerForTraitChanges([UITraitHorizontalSizeClass.self, UITraitVerticalSizeClass.self]) {
        (probe: LayoutProbe, _: UITraitCollection) in probe.onChange?()
      }
    }
  }

  required init?(coder: NSCoder) { nil }

  override func layoutSubviews() {
    super.layoutSubviews()
    onChange?()
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if #unavailable(iOS 17.0) { onChange?() }
  }

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? { nil }
}
