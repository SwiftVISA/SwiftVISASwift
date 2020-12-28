// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "SwiftVISASwift",
	products: [
		// Products define the executables and libraries a package produces, and make them visible to other packages.
		.library(
			name: "SwiftVISASwift",
			targets: ["SwiftVISASwift"]),
	],
	dependencies: [
		// Dependencies declare other packages that this package depends on.
		// .package(url: /* package url */, from: "1.0.0"),
		.package(path: "../CoreSwiftVISA"),
		.package(url: "https://github.com/yeokm1/SwiftSerial.git", from: "0.1.2"),
		.package(name: "Socket", url: "https://github.com/IBM-Swift/BlueSocket.git", from: "1.0.0")
	],
	targets: [
		// Targets are the basic building blocks of a package. A target can define a module or a test suite.
		// Targets can depend on other targets in this package, and on products in packages this package depends on.
		.target(
			name: "SwiftVISASwift",
			dependencies: ["CoreSwiftVISA", "Socket", "SwiftSerial"]),
		.testTarget(
			name: "SwiftVISASwiftTests",
			dependencies: ["SwiftVISASwift"]),
	]
)
