
import Foundation
import XCTest
@testable import ErrorBacktrace

final class BacktraceTests: XCTestCase {

	func testCaptureFromLocalError() {
		struct AnError: Error { }
		let subject = { throw AnError() }

		XCTAssertThrowsError(try Backtrace.capture(from: subject)) { error in
			XCTAssert(error is CapturedBacktrace)
			XCTAssertNotNil((error as? CapturedBacktrace)?.backtrace)
		}
	}

	func testCaptureFromBridgedError() {
		let subject = { try FileManager.default.createDirectory(atPath: "/", withIntermediateDirectories: false) }

		XCTAssertThrowsError(try Backtrace.capture(from: subject)) { error in
			XCTAssert(error is CapturedBacktrace)
			XCTAssertNotNil((error as? CapturedBacktrace)?.backtrace)
		}
	}

	func testDebugSymbols() throws {
		try XCTSkipUnless(FileManager.default.fileExists(atPath: "/usr/bin/atos"))
		let subject = Backtrace.current
		let firstAtosLine = try XCTUnwrap(subject.debugSymbols?.first)

		XCTAssert(
			firstAtosLine.contains("BacktraceTests.swift"),
			"Expected \"\(firstAtosLine)\" to mention of BacktraceTests.swift"
		)
	}

	func testDebugSymbolsPerformance() throws {
		try XCTSkipUnless(FileManager.default.fileExists(atPath: "/usr/bin/atos"))

		measure {
			XCTAssertNotNil(Backtrace.current.debugSymbols)
		}
	}

	func testSymbols() throws {
		let subject = Backtrace.current
		let firstSymbolLine = try XCTUnwrap(subject.symbols.first)

		XCTAssert(
			firstSymbolLine.contains("BacktraceTests"),
			"Expected \"\(firstSymbolLine)\" to mention this image name"
		)
		XCTAssert(
			firstSymbolLine.contains("testSymbols"),
			"Expected \"\(firstSymbolLine)\" to mention this symbol name"
		)
	}
}
