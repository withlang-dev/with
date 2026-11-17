//! expect-check-fail: 'ok' lists several success statuses, and a copied-back length is presented under one success status
//! expect-check-fail: = help: list one success status: 'ok <CONST>'

// #3129 (§16.2b.4): a length C writes back means one thing under one status.
use c_import("#define A_OK 0
#define B_OK 1
int two(unsigned char *dst, unsigned long *n);
")

c contract lib:
    fn two
        buffer param dst capacity param n inout
        ok A_OK, B_OK

fn main:
    print("unreachable")
