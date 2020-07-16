
import Foundation

import ErrorBacktrace
//import CErrorBacktrace

func foo() throws {
	struct Error: Swift.Error { let s: String }

//	throw Error(s: "oogabooga")

	try FileManager.default.createDirectory(atPath: "/Users/herooftime/egg-freckles/nope", withIntermediateDirectories: false)
}

#if canImport(ArgumentParser)
import ArgumentParser
#endif

struct Example: ParsableCommand {
	func run() throws {
		try Backtrace.capture { try foo() }
	}
}

Example.main()
