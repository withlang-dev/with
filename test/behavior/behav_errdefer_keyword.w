//! expect-stdout: ok

extern fn with_eprint(s: str)

var errdefer_ran: i32 = 0

fn might_fail:
    errdefer errdefer_ran = errdefer_ran + 1

fn main:
    might_fail()
    // errdefer only runs if function returns error — here it doesn't
    assert(errdefer_ran == 0)
    print("ok")
