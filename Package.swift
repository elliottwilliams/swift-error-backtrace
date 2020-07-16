// swift-tools-version:5.2
import PackageDescription

let package = Package(
	name: "swift-error-backtrace",
	platforms: [
		.macOS(.v10_12),
	],
	products: [
		.library(name: "ErrorBacktrace", targets: ["ErrorBacktrace"]),
		.executable(name: "example", targets: ["example"]),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser", from: "0.0.1"),
	],
	targets: [
		.target(name: "ErrorBacktrace", swiftSettings: [.define("UNSAFE_DEMANGLE")]),
		.target(name: "example", dependencies: [
			"ErrorBacktrace",
			.product(name: "ArgumentParser", package: "swift-argument-parser")
			]),
	]
)
