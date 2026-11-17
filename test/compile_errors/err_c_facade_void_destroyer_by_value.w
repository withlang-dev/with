//! expect-check-fail: 'release' does not take the representation as its first parameter
//! expect-check-fail: = help: an operation of 'Fd' takes what it wraps first; describe 'release' with an fn item when the resource is a later parameter (no destroyer form exists for that: #3177)

// Ruling §61 (Eric, 2026-09-22): a `void *` destroyer accepts object pointer
// representations only, never a by-value representation.

use c_import("int fd_new(int id);\nvoid release(void* p);\n")

c contract fds:
    resource Fd wraps c_int
        from fd_new
        drop release

fn main:
    print("ok")
