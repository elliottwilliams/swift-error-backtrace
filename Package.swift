// swift-tools-version:5.2
import PackageDescription

let package = Package(
	name: "swift-error-backtrace",
	platforms: [
		.macOS(.v10_13),
	],
	products: [
		.library(name: "ErrorBacktrace", targets: ["ErrorBacktrace"]),
	],
	dependencies: [
	],
	targets: [
		.target(name: "ErrorBacktrace"),
		.testTarget(name: "BacktraceTests", dependencies: ["ErrorBacktrace"])
	]
)
