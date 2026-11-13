//! expect-stdout: done
// #3292: code translated from an imported header calls the functions the
// header names. The translator rewrote a header's `free(s)` to the
// runtime's allocator, so freeing memory libc allocated (strdup's) panicked
// "invalid free: pointer is not an allocated payload start".
use c_import("char *strdup(const char *s);
void free(void *p);
static inline void lib_release(char *s) { free(s); }
static inline char *lib_copy(void) { return strdup(\"abc\"); }
")

fn main:
    unsafe { lib_release(lib_copy()) }
    print("done")
