import Flutter
import QuartzCore
import UIKit

public class FoldAdaptiveNavIosPlugin: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
  private weak var registrar: FlutterPluginRegistrar?
  private let monitor = FoldMonitor()
  private let stateStream = StateStreamHandler()
  private let angleStream = AngleStreamHandler()

  init(registrar: FlutterPluginRegistrar) {
    self.registrar = registrar
    super.init()
    monitor.onState = { [weak self] state in self?.stateStream.send(state) }
    monitor.onAngle = { [weak self] degrees in self?.angleStream.push(degrees) }
    stateStream.onListen = { [weak self] in
      guard let self else { return nil }
      self.attachIfPossible()
      return self.monitor.snapshot()
    }
    angleStream.onListen = { [weak self] in
      self?.attachIfPossible()
      return self?.monitor.latestAngle
    }
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FoldAdaptiveNavIosPlugin(registrar: registrar)
    let messenger = registrar.messenger()
    registrar.addMethodCallDelegate(
      instance,
      channel: FlutterMethodChannel(name: "fold_adaptive_nav/methods", binaryMessenger: messenger))
    FlutterEventChannel(name: "fold_adaptive_nav/state", binaryMessenger: messenger)
      .setStreamHandler(instance.stateStream)
    FlutterEventChannel(name: "fold_adaptive_nav/angle", binaryMessenger: messenger)
      .setStreamHandler(instance.angleStream)
    registrar.addSceneDelegate(instance)

    FoldVerticalBar.install(on: FoldFlutterViewController.self)
    FoldVerticalBar.installOnFlutterViewControllerIfRequested()
    instance.attachIfPossible()
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "snapshot":
      attachIfPossible()
      result(monitor.snapshot())
    case "setVerticalSystemBarDisabled":
      let disabled = (call.arguments as? [String: Any])?["disabled"] as? Bool ?? true
      FoldVerticalBar.setDisabled(disabled, from: registrar?.viewController)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: FlutterSceneLifeCycleDelegate

  public func sceneWillEnterForeground(_ scene: UIScene) {
    attachIfPossible()
  }

  public func sceneDidBecomeActive(_ scene: UIScene) {
    attachIfPossible()
    // A controller that was created before registration missed route 2.
    FoldVerticalBar.requestUpdate(registrar?.viewController)
  }

  /// The view controller can arrive after registration with scenes, so try
  /// again whenever Dart asks or the scene becomes active.
  private func attachIfPossible() {
    guard let view = registrar?.viewController?.view else { return }
    monitor.attach(to: view)
  }
}

/// `fold_adaptive_nav/state`: sends the current state on listen, then changes.
final class StateStreamHandler: NSObject, FlutterStreamHandler {
  var onListen: (() -> [String: Any]?)?
  private var sink: FlutterEventSink?

  func send(_ state: [String: Any]) { sink?(state) }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    sink = events
    if let state = onListen?() { events(state) }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }
}

/// `fold_adaptive_nav/angle`: at most one value per display frame, and only
/// when it changed. The display link pauses while the hinge is still.
final class AngleStreamHandler: NSObject, FlutterStreamHandler {
  var onListen: (() -> Double?)?
  private var sink: FlutterEventSink?
  private var link: CADisplayLink?
  private var latest: Double?
  private var lastSent: Double?

  func push(_ degrees: Double) {
    latest = degrees
    link?.isPaused = false
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    sink = events
    lastSent = nil
    if let current = onListen?() { latest = current }
    let link = CADisplayLink(target: self, selector: #selector(tick))
    link.add(to: .main, forMode: .common)
    self.link = link
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    link?.invalidate()  // releases the link's strong reference to self
    link = nil
    sink = nil
    return nil
  }

  @objc private func tick() {
    guard let latest, latest != lastSent else {
      link?.isPaused = true
      return
    }
    lastSent = latest
    sink?(latest)
  }
}
