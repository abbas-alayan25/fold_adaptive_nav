// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "fold_adaptive_nav_ios",
  platforms: [
    .iOS("15.0")
  ],
  products: [
    .library(name: "fold-adaptive-nav-ios", targets: ["fold_adaptive_nav_ios"])
  ],
  dependencies: [
    .package(name: "FlutterFramework", path: "../FlutterFramework")
  ],
  targets: [
    .target(
      name: "fold_adaptive_nav_ios",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework")
      ],
      resources: [
        .process("PrivacyInfo.xcprivacy")
      ],
      swiftSettings: [
        // The typed iOS 27.1 API path; needs Xcode 27.1. Without it the plugin
        // resolves the same APIs through the Objective-C runtime.
        // .define("FOLD_NATIVE_API")
      ]
    )
  ]
)
