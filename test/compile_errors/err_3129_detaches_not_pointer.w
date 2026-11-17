//! expect-check-fail: not a pointer, there is nothing to detach
//! expect-check-fail: = help: delete the 'detaches' clause: it names the pointer parameter that receives a resource

// #3129 (§16.2b.6): `detaches` names a pointer parameter.
use c_import("static inline int add3(int a, int b) { return a + b; }\n")

c contract adds:
    fn add3
        detaches param a

fn main:
    print("unreachable")
