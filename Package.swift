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
    .package(url: "https://github.com/SwiftVISA/BlueSocket.git", .branch("master") )
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
