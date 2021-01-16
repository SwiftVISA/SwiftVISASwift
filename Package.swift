// swift-tools-version:5.0

import PackageDescription

let package = Package(
	name: "SwiftVISASwift",
	products: [
		.library(
			name: "SwiftVISASwift",
			targets: ["SwiftVISASwift"]),
	],
	dependencies: [
		.package(url: "https://github.com/SwiftVISA/CoreSwiftVISA.git", .upToNextMinor(from: "0.1.0")),
		.package(url: "https://github.com/IBM-Swift/BlueSocket.git", from: "1.0.0")
	],
	targets: [
		.target(
			name: "SwiftVISASwift",
			dependencies: ["CoreSwiftVISA", "Socket"]),
		.testTarget(
			name: "SwiftVISASwiftTests",
			dependencies: ["SwiftVISASwift"]),
	]
)
