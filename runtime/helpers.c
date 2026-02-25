// With Language Runtime Helpers
// Small C wrapper functions for stdlib features that need special handling.

#include <time.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

// time(NULL) wrapper — Zig/LLVM has trouble with NULL pointer args
int64_t with_time_now(void) {
    return (int64_t)time(NULL);
}

// getenv wrapper that returns "" instead of NULL for missing vars
const char *with_getenv(const char *name) {
    const char *val = getenv(name);
    return val ? val : "";
}
