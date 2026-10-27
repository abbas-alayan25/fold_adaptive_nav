import Flutter
import ObjectiveC
import UIKit

/// iOS 27.1+: on the closed iPhone Duo the system moves the status bar and
/// native bars into a vertical strip down the trailing edge. A Flutter app that
/// draws its own tabs wants the horizontal status bar back, which only a
/// view-controller override of `preferredVerticalBarBehavior` can ask for.
///
/// Two routes, both reading `FoldVerticalBar.disabled`:
/// 1. `FoldFlutterViewController` (recommended): set it as the storyboard's
///    root controller.
/// 2. Info.plist `FoldAdaptiveNavDisableVerticalBar = YES`: the plugin adds the
///    property to `FlutterViewController` with `class_addMethod`, which adds
///    rather than swizzles because FlutterViewController doesn't define it.
///
/// Treat it as a stable, app-wide choice; don't flip it per screen.
enum FoldVerticalBar {
  static let infoPlistKey = "FoldAdaptiveNavDisableVerticalBar"
  private static let behaviorSelector = NSSelectorFromString("preferredVerticalBarBehavior")
  private static let updateSelector = NSSelectorFromString(
    "setNeedsUpdateOfVerticalBarConfiguration")

  /// `UIVerticalBarBehavior.disabled` when true, `.automatic` otherwise.
  static var disabled: Bool = infoPlistValue ?? false

  static var infoPlistValue: Bool? {
    Bundle.main.object(forInfoDictionaryKey: infoPlistKey) as? Bool
  }

  /// The running UIKit knows about vertical bars.
  static var isSupported: Bool {
    UIViewController.instancesRespond(to: behaviorSelector)
  }

  /// Route 2: only when the app opted in through Info.plist.
  static func installOnFlutterViewControllerIfRequested() {
    if infoPlistValue == true { install(on: FlutterViewController.self) }
  }

  /// Adds `preferredVerticalBarBehavior` to `cls`. Does nothing if the class
  /// already implements it itself, or on systems without vertical bars.
  @discardableResult
  static func install(on cls: AnyClass) -> Bool {
    guard isSupported else { return false }
    let implementation: @convention(block) (AnyObject) -> Int = { _ in
      disabled ? 1 : 0  // UIVerticalBarBehaviorDisabled : UIVerticalBarBehaviorAutomatic
    }
    // "q@:" = returns NSInteger, takes self and _cmd.
    return class_addMethod(
      cls, behaviorSelector, imp_implementationWithBlock(implementation), "q@:")
  }

  /// Changes the preference and asks UIKit to read it again.
  static func setDisabled(_ value: Bool, from controller: UIViewController?) {
    disabled = value
    requestUpdate(controller)
    requestUpdate(controller?.view.window?.rootViewController)
  }

  static func requestUpdate(_ controller: UIViewController?) {
    guard let controller, controller.responds(to: updateSelector) else { return }
    controller.perform(updateSelector)
  }
}

/// A `FlutterViewController` that turns the vertical system bar off.
///
/// In `ios/Runner/Base.lproj/Main.storyboard`, set the root controller's
/// `customClass="FoldFlutterViewController"` and
/// `customModule="fold_adaptive_nav_ios"`.
open class FoldFlutterViewController: FlutterViewController {
  #if FOLD_NATIVE_API
    @available(iOS 27.1, *)
    open override var preferredVerticalBarBehavior: UIVerticalBarBehavior {
      FoldVerticalBar.disabled ? .disabled : .automatic
    }
  #endif

  open override func viewDidLoad() {
    #if !FOLD_NATIVE_API
      FoldVerticalBar.install(on: FoldFlutterViewController.self)
    #endif
    // Choosing this controller is the opt-in; Info.plist can still say NO.
    FoldVerticalBar.disabled = FoldVerticalBar.infoPlistValue ?? true
    super.viewDidLoad()
    FoldVerticalBar.requestUpdate(self)
  }
}
