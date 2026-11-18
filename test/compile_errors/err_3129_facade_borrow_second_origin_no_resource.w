//! expect-check-fail: fn 'node_child': 'returns borrow Node from params 0, 1' names param 1: i32 i, which receives no modeled resource, and With does not invent an origin (§16.2b.7)
//! expect-check-fail: = help: after 'from params' name parameters that each receive a declared resource

// #3129 (§16.2b.6): each origin of a borrowed resource receives a declared resource.
use c_import("typedef struct node node;\nnode *node_new(void);\nvoid node_free(node *n);\nnode *node_child(node *n, int i);\nconst char *node_text(node *n, int k);\nnode *node_at(int i, node *n);\n")

c contract tree:
    resource Node wraps *mut node
        from node_new
        drop node_free
    fn node_child
        returns borrow Node from params 0, 1

fn main:
    print(1)
