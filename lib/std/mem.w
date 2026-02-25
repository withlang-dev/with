// std.mem — Memory allocation and manipulation
//
// Provides heap allocation and memory operations wrapping C stdlib.

use c_import("#include <stdlib.h>\n#include <string.h>")

// Allocate size bytes on the heap. Returns pointer (0 on failure).
pub fn alloc(size: i64) -> *i8 =
    malloc(size)

// Allocate and zero-initialize n*size bytes.
pub fn alloc_zeroed(count: i64, size: i64) -> *i8 =
    calloc(count, size)

// Resize a heap allocation. Returns new pointer (0 on failure).
pub fn realloc_mem(ptr: *i8, new_size: i64) -> *i8 =
    realloc(ptr, new_size)

// Free a heap allocation.
pub fn free_mem(ptr: *i8) -> void =
    free(ptr)

// Copy n bytes from src to dst (non-overlapping).
pub fn mem_copy(dst: *i8, src: *i8, n: i64) -> *i8 =
    memcpy(dst, src, n)

// Move n bytes from src to dst (may overlap).
pub fn mem_move(dst: *i8, src: *i8, n: i64) -> *i8 =
    memmove(dst, src, n)

// Set n bytes to value c.
pub fn mem_set(ptr: *i8, c: i32, n: i64) -> *i8 =
    memset(ptr, c, n)

// Compare n bytes of two memory regions.
pub fn mem_cmp(a: *i8, b: *i8, n: i64) -> i32 =
    memcmp(a, b, n)
