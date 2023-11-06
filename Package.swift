// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "SwiftVISASwift",
  platforms: [.macOS("12.0")],
  products: [
    .library(
      name: "SwiftVISASwift",
      targets: ["SwiftVISASwift"]),
  ],
  dependencies: [
    .package(url: "https://github.com/SwiftVISA/CoreSwiftVISA.git", .branch("actor")),
    .package(url: "https://github.com/IBM-Swift/BlueSocket.git", from: "1.0.0")
  ],
  targets: [
    .target(
      name: "SwiftVISASwift",
      dependencies: ["CoreSwiftVISA", .product(name: "Socket", package: "BlueSocket")]),
    .testTarget(
      name: "SwiftVISASwiftTests",
      dependencies: ["SwiftVISASwift"]),
  ]
)
