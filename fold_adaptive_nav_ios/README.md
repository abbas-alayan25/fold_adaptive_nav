# fold_adaptive_nav_ios

The iOS implementation of [`fold_adaptive_nav`](https://pub.dev/packages/fold_adaptive_nav).
It is endorsed, so you don't add it to your app yourself: `fold_adaptive_nav`
pulls it in.

- Hinge posture and angle: `UIHingeInteraction` (iOS 27.1+).
- Fold and camera regions: `UIView.reservedRegions(kind:options:)`.
- Size classes, through trait-change registration.
- `FoldFlutterViewController`, which turns the vertical system bar off on the
  cover display.

By default the 27.1 APIs are resolved through the Objective-C runtime, so the
plugin builds with older Xcode versions and reports "not a foldable" where the
APIs are missing. To use the typed Swift API instead (needs Xcode 27.1),
uncomment `OTHER_SWIFT_FLAGS = -DFOLD_NATIVE_API` in the podspec or
`.define("FOLD_NATIVE_API")` in `Package.swift`.

Deployment target: iOS 15.0. CocoaPods and Swift Package Manager are both
supported. The plugin uses the UIScene lifecycle.
