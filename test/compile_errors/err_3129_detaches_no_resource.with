//! expect-check-fail: which receives no one modeled resource; a detached value is the resource its parameter receives
//! expect-check-fail: = help: declare the resource the pointer is ('resource Name wraps *mut T'), then 'detaches param N' names the parameter that receives it

// #3129 (§16.2b.6): `detaches` names a parameter that receives a resource.
use c_import("typedef struct node node;\nvoid unlink_node(node *n);\n")

c contract nodes:
    fn unlink_node
        detaches param n

fn main:
    print("unreachable")
