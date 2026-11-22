//! expect-check-fail: fn 'node_text': 'from params 0, 1' names param 1: i32 k, which receives no modeled resource; a borrowed value is a view of what each origin parameter receives
//! expect-check-fail: = help: after 'from params' name two parameters that each receive a declared resource or a C string

// #3129 (§16.2b.6, §16.2b.7): With does not invent an origin: each origin of borrowed text receives a resource or a C string.
use c_import("typedef struct node node;\nnode *node_new(void);\nvoid node_free(node *n);\nnode *node_child(node *n, int i);\nconst char *node_text(node *n, int k);\nnode *node_at(int i, node *n);\n")

c contract tree:
    resource Node wraps *mut node
        from node_new
        drop node_free
    fn node_text
        returns borrow CStr from params 0, 1

fn main:
    print(1)
