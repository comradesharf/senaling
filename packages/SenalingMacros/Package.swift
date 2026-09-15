// swift-tools-version: 6.2

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "SenalingMacros",
  platforms: [
    .macOS(.v15)
  ],
  products: [
    .library(
      name: "SenalingMacros",
      targets: ["SenalingMacros"]
    )
  ],
  dependencies: [
    .package(
      url: "https://github.com/swiftlang/swift-syntax.git",
      from: "602.0.0"
    )
  ],
  targets: [
    .macro(
      name: "SenalingMacrosPlugin",
      dependencies: [
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
      ]
    ),
    .target(
      name: "SenalingMacros",
      dependencies: ["SenalingMacrosPlugin"]
    ),
    .testTarget(
      name: "SenalingMacrosTests",
      dependencies: [
        "SenalingMacrosPlugin",
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
      ]
    ),
  ]
)
