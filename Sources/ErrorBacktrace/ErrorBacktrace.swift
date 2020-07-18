import Foundation

private let kThrownCallStack = "swift-error-backtrace-ThrownCallStack"

// Overshadows the `swift_willThrow` function in the standard library. The compiler emits a call to
// `swift_willThrow` when generating a `throw` statement.
//
// Only binaries that link against `ErrorBacktrace` are expected to use this implementation of
// `swift_willThrow` instead of the standard library's. Runtime dynamic linker shenanigans are inherently
// unsafe and hard to predict -- it's possible that this implementation will never be called, or will be
// called at unexpected times.
//
// While knowledge of `swift_willThrow` is shared between Swift and Xcode, its existence and behavior is
// undocumented and subject to change at any time.
@_cdecl("swift_willThrow")
@inline(never)
func swift_willThrow() {
  Thread.current.threadDictionary.setValue(
    Thread.callStackReturnAddresses[2...],
    forKey: kThrownCallStack
  )
}

public struct Backtrace: CustomStringConvertible {
	/// Pointers to the stack frames of this backtrace, suitable for passing to `backtrace(3)` or other system library functions.
  public var callStack: [UnsafeRawPointer]

	/// A string representation of the stack trace using runtime-provided information.
  public var symbols: [String] {
    var info = Dl_info()
    let nameBuffer = UnsafeMutablePointer<Int8>.allocate(capacity: Int(MAXPATHLEN))
    defer { nameBuffer.deallocate() }

    return callStack.enumerated().map { frameNumber, addr in
      guard dladdr(addr, &info) != 0 else {
        return String(format: "%5d  ???", frameNumber)
      }
      let symbolAddress = UnsafeRawPointer(info.dli_saddr)!
      let frameOffset = symbolAddress.distance(to: addr)
      let frameworkName = OpaquePointer(basename_r(info.dli_fname, nameBuffer)!)
      let symbolName = info.dli_sname!
      return String(format: "%5d  %-33s %-16p %s + %d",
                    frameNumber, frameworkName, OpaquePointer(symbolAddress), symbolName, frameOffset)
    }
  }

	/// A string representation of the stack trace using demangled names and line information, if available.
	///
	/// Returns nil if `atos(1)` is not available on this system. For a more performant API, use `symbols`.
  public var debugSymbols: [String]? {
    let atosURL = URL(fileURLWithPath: "/usr/bin/atos")
    guard (try? atosURL.checkResourceIsReachable()) ?? false else {
      return nil
    }

    let process = Process()
    let pipe = Pipe()
    process.executableURL = atosURL
    process.arguments  = ["-p", String(ProcessInfo.processInfo.processIdentifier)] +
      callStack.map({ String(format: "%p", OpaquePointer($0)) })
    process.standardOutput = pipe
    process.launch()
    process.waitUntilExit()
		guard process.terminationStatus == 0 else {
			return nil
		}

    let atosLines = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?.split(separator: "\n")
    return atosLines?.enumerated().map({ String(format: "%5d  ", $0) + $1 }) ?? []
  }

  public var description: String {
    (debugSymbols ?? symbols).joined(separator: "\n")
  }

	/// The backtrace for the current stack frame.
	public static var current: Backtrace {
		let callStack = Thread.callStackReturnAddresses[1...].map { UnsafeRawPointer(bitPattern: $0.uintValue)! }
		return Backtrace(callStack: callStack)
	}

	/// The backtrace at the last time an error was thrown on this thread.
	public static var lastThrown: Backtrace? {
		return lastThrownBacktrace(on: .current)
	}

	/// The backtrace at the last time an error was thrown on the given `thread`.
	public static func lastThrownBacktrace(on thread: Thread) -> Backtrace? {
		let capturedReturnAddresses = thread.threadDictionary.value(forKey: kThrownCallStack) as! ArraySlice<NSNumber>?
		let callStack = capturedReturnAddresses?.map { UnsafeRawPointer(bitPattern: $0.uintValue)! }
		return callStack.map(Backtrace.init)
	}

	/// Calls `body` and wraps any error it throws in a type that describes the backtrace when it was thrown.
  public static func capture<V>(from body: () throws -> V) throws -> V {
    do {
      return try body()
    } catch {
      let wrapper = CapturedBacktrace(error: error, backtrace: lastThrown)
      throw wrapper
    }
  }
}

struct CapturedBacktrace: Error, CustomStringConvertible {
	let error: Error
	let backtrace: Backtrace?

	public var description: String {
		"""
		\(error)

		Backtrace:
		\(backtrace?.description ?? "Unable to collect a backtrace for this error.")
		"""
	}
}
