// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "InlineFlowSeparatorLayout",
  platforms: [
    .iOS(.v18)
  ],
  products: [
    .library(name: "InlineFlowSeparatorLayout", targets: [
      "InlineFlowSeparatorLayout"
    ])
  ],
  targets: [
    .target(name: "InlineFlowSeparatorLayout")
  ],
  swiftLanguageModes: [.v6]
)
