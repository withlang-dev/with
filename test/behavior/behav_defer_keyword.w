//! expect-stdout: ok

extern fn with_eprint(s: str)

var cleanup_count: i32 = 0

fn with_cleanup:
    defer cleanup_count = cleanup_count + 1

fn main:
    with_cleanup()
    assert(cleanup_count == 1)
    print("ok")
