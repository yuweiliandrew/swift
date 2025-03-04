// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "SwiftCompilerSources",
  platforms: [
    .macOS("10.9"),
  ],
  products: [
    .library(
      name: "Swift",
      type: .static,
      targets: ["SIL", "Optimizer", "_RegexParser"]),
  ],
  dependencies: [
  ],
  // Note that all modules must be added to LIBSWIFT_MODULES in the top-level
  // CMakeLists.txt file to get debugging working.
  targets: [
    .target(
      name: "SIL",
      dependencies: [],
      swiftSettings: [SwiftSetting.unsafeFlags([
          "-I", "../include/swift",
          "-cross-module-optimization"
        ])]),
    .target(
      name: "_RegexParser",
      dependencies: [],
      swiftSettings: [SwiftSetting.unsafeFlags([
          "-I", "../include/swift",
          "-cross-module-optimization"
        ])]),
    .target(
      name: "Optimizer",
      dependencies: ["SIL", "_RegexParser"],
      swiftSettings: [SwiftSetting.unsafeFlags([
          "-I", "../include/swift",
          "-cross-module-optimization"
        ])]),
  ]
)
