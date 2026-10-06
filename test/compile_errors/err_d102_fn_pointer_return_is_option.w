//! expect-check-fail: type mismatch

// D102 (§16.6): C hands the program a function pointer through a return,
// so `pick` returns `Option[op_t]`; binding it to the non-null typedef is
// a type mismatch, and the program must check it first.
use c_import("typedef int (*op_t)(int);
op_t pick(int which);")

fn main:
    let f: op_t = unsafe { pick(0) }
    print(f(1))
