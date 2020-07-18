import XCTest

import BacktraceTests

var tests = [XCTestCaseEntry]()
tests += BacktraceTests.__allTests()

XCTMain(tests)
