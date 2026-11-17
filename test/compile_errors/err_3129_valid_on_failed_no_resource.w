//! expect-check-fail: 'valid on failed' marks an operation of the failed state of the resource its first parameter receives
//! expect-check-fail: = help: delete 'valid on failed', or make the failed resource the function's first parameter

// #3129 (§16.2b.4): a failed state is a resource's; a function that takes
// no resource has none.
use c_import("typedef struct h h;
h *h_new(void);
void h_free(h *x);
typedef struct row { int a; } row;
const char *h_two(int a, int b);
row *h_row(int k);
const char *h_msg(int code);
int h_fail(int x);
int h_of(int x);
#define H_OK 0
")

c contract lib:
    resource Handle wraps *mut h
        from h_new
        drop h_free
    fn h_fail
        valid on failed

fn main:
    print("unreachable")
