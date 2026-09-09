// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SenalingBinding",
  platforms: [
    .macOS(.v13)
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "SenalingBinding",
      type: .dynamic,
      targets: ["SenalingBinding"]
    )
  ],
  targets: [
    .systemLibrary(
      name: "SenalingBindingFFI",
      path: "Sources/SenalingBindingFFI"
    ),
    .target(
      name: "SenalingBinding",
      dependencies: ["SenalingBindingFFI"],
      path: "Sources/SenalingBinding",
      linkerSettings: [
        .unsafeFlags([
          "-L", "../../target/debug",
        ]),
        .linkedLibrary("senaling_binding"),
      ]
    ),
  ]
)
