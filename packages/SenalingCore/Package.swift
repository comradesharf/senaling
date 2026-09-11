// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SenalingCore",
  platforms: [
    .macOS(.v15)
  ],
  products: [
    .library(
      name: "SenalingCore",
      targets: ["SenalingCore"]
    )
  ],
  targets: [
    .target(
      name: "SenalingCore",
      dependencies: ["SenalingCoreFFI"],
      path: "Sources/SenalingCore"
    ),
    .binaryTarget(
      name: "SenalingCoreFFI",
      path: "Frameworks/SenalingCoreFFI.xcframework"
    ),
  ]
)
