
#include "backtrace3.h"
#include <pthread.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <execinfo.h>

#define MAX_FRAMES 128

static pthread_key_t kThrownStackFrames;
static pthread_key_t kThrownStackSize;

void swift_willThrow() {
	// Create keys for thread-local storage.
	if (OS_EXPECT(!kThrownStackFrames, 0))
		pthread_key_create(&kThrownStackFrames, free);
	if (OS_EXPECT(!kThrownStackSize, 0))
		pthread_key_create(&kThrownStackSize, NULL);

	// Ensure a buffer is allocated for this thread to write call stack addresses to.
	void **frames = pthread_getspecific(kThrownStackFrames);
	if (OS_EXPECT(!frames, 0))
		frames = malloc(sizeof(void *) * MAX_FRAMES);
	if (OS_EXPECT(!frames, 0)) {
		perror("Failed to allocate memory to store thrown error backtrace");
		return;
	}

	// Record call stack addresses, and store the size of the backtrace.
	int size = backtrace(frames, MAX_FRAMES);
	pthread_setspecific(kThrownStackSize, size);
}

void PrintLastSwiftErrorBacktrace() {
	void **frames = pthread_getspecific(kThrownStackFrames);
	int size = pthread_getspecific(kThrownStackSize);

	// If a backtrace was never recorded for this thread, stop.
	if (!frames || !size)
		return;

	// Print the backtrace, removing the topmost frame which is `swift_willThrow` itself.
	fputs("Last error backtrace:\n", stderr);
	backtrace_symbols_fd(frames+1, size-1, STDERR_FILENO);
}
