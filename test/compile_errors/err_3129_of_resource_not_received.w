//! expect-check-fail: it receives no modeled resource (§16.2b.3)
//! expect-check-fail: = help: delete 'of Handle'

// #3129 (§16.2b.3): 'of R' picks among the resources a parameter receives;
// an int parameter receives none.
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
    fn h_of
        of Handle

fn main:
    print("unreachable")
