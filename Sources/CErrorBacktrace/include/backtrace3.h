/*!
 Looks up the call stack from the last time an Swift error was thrown on the current thread, and prints it to standard error.

 Call this function at the start of a @c catch block to print a backtrace for the error that was caught:

 @code
 do {
	 try call()
 } catch {
	 fputs("Caught error: \(error)\n", stderr)
	 PrintLastSwiftErrorBacktrace()
 }
 @endcode

 If no error has been recorded for this thread, nothing is printed.
 */
void PrintLastSwiftErrorBacktrace();
