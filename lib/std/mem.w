// std.mem — Memory allocation and manipulation
//
// Provides heap allocation and memory operations via the runtime interface.
// No c_import — all operations go through with_* runtime functions
// backed by the freelist allocator in rt_core.

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_alloc_zeroed(count: i64, size: i64) -> *mut u8
extern fn with_realloc(ptr: *mut u8, old_size: i64, new_size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit
extern fn with_free_sized(ptr: *mut u8, size: i64) -> Unit
extern fn with_memcpy(dst: *mut u8, src: *const u8, n: i64) -> *mut u8
extern fn with_memmove(dst: *mut u8, src: *const u8, n: i64) -> *mut u8
extern fn with_memset(dst: *mut u8, c: i32, n: i64) -> *mut u8
extern fn with_memcmp(a: *const u8, b: *const u8, n: i64) -> i32

/// Allocate `size` bytes on the heap. Returns pointer (0 on failure).
pub fn alloc(size: i32) -> *i8:
    with_alloc(size as i64) as *i8

/// Allocate and zero-initialize `count * size` bytes.
pub fn alloc_zeroed(count: i32, size: i32) -> *i8:
    with_alloc_zeroed(count as i64, size as i64) as *i8

/// Resize a heap allocation. Returns new pointer (0 on failure).
pub fn realloc_mem(ptr: *i8, new_size: i32) -> *i8:
    // Note: old_size not tracked in this API; pass 0 (fallback path in allocator)
    with_realloc(ptr as *mut u8, 0, new_size as i64) as *i8

/// Free a heap allocation.
pub fn free_mem(ptr: *i8) -> Unit:
    with_free(ptr as *mut u8)

/// Copy `n` bytes from `src` to `dst` (must not overlap).
pub fn mem_copy(dst: *i8, src: *i8, n: i32) -> *i8:
    with_memcpy(dst as *mut u8, src as *const u8, n as i64)
    dst

/// Move `n` bytes from `src` to `dst` (may overlap).
pub fn mem_move(dst: *i8, src: *i8, n: i32) -> *i8:
    with_memmove(dst as *mut u8, src as *const u8, n as i64)
    dst

/// Set `n` bytes starting at `ptr` to value `c`.
pub fn mem_set(ptr: *i8, c: i32, n: i32) -> *i8:
    with_memset(ptr as *mut u8, c, n as i64)
    ptr

/// Compare `n` bytes of two memory regions. Returns 0 if equal.
pub fn mem_cmp(a: *i8, b: *i8, n: i32) -> i32:
    with_memcmp(a as *const u8, b as *const u8, n as i64)
