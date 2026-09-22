//! expect-check-fail: 'release' does not take the representation as its first parameter

// Ruling §61 (Eric, 2026-09-22): a `void *` destroyer accepts object pointer
// representations only. A function pointer does not convert to `void *` in
// standard C, so a resource wrapping one is not destroyed by `void release(void *)`.

use c_import("typedef void (*hook)(int);\nhook hook_new(int id);\nvoid release(void* p);\n")

c facade hooks:
    resource Hook wraps hook
        from hook_new
        drop release

fn main:
    print("ok")
