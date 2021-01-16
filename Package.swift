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
		.package(path: "../CoreSwiftVISA"),
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
