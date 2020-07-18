import Foundation
#if canImport(ArgumentParser)

import ArgumentParser

public protocol BacktraceCapturingCommand: ParsableCommand {
	/// Runs this command, and wraps any error it throws in a type that describes the backtrace where the error was thrown.
	func runAndCaptureError() throws
}

extension BacktraceCapturingCommand {
	public func run() throws {
		try Backtrace.capture(from: runAndCaptureError)
	}
}

#endif
