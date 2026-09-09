// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SenalingBinding",
  platforms: [
    .macOS(.v15)
  ],
  products: [
    .library(
      name: "SenalingBinding",
      targets: ["SenalingBinding"]
    )
  ],
  targets: [
    .binaryTarget(
      name: "SenalingBindingFFI",
      path: "Frameworks/SenalingBindingFFI.xcframework"
    ),
    .target(
      name: "SenalingBinding",
      dependencies: ["SenalingBindingFFI"],
      path: "Sources/SenalingBinding"
    ),
  ]
)
