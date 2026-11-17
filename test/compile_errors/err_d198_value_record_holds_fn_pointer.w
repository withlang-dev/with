//! expect-check-fail: a value record is flat, and field 'op'
//! expect-check-fail: = help: declare the record a resource ('resource Name wraps *mut T' with its producer and 'drop'), or leave the function raw
// D198 (§16.2b.5): a function pointer the callee calls is a pointer it follows.
use c_import("typedef struct { int (*op)(int); int seed; } Ops; static inline int ops_run(const Ops *o) { return o->op(o->seed); }")

c contract ops:
    fn ops_run
        reads param o

fn main:
    print("unreachable")
