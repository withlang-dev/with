//! expect-check-fail: fn 'node_at': 'returns borrow Node' is presented as a lend method of the resource its first parameter receives, and param 0: i32 i receives none it can be a method of
//! expect-check-fail: = help: make the resource the result lives in the first parameter's resource, or leave the function raw

// #3129 (§16.2b.6): a borrowed return is a method of the resource the first parameter receives.
use c_import("typedef struct node node;\nnode *node_new(void);\nvoid node_free(node *n);\nnode *node_child(node *n, int i);\nconst char *node_text(node *n, int k);\nnode *node_at(int i, node *n);\n")

c contract tree:
    resource Node wraps *mut node
        from node_new
        drop node_free
    fn node_at
        returns borrow Node from param 1

fn main:
    print(1)
