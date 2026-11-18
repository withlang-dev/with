//! expect-check-fail: fn 'node_size': param 0: *mut node n receives a representation several resources wrap ('Node', 'Leaf'); an operation is callable through a resource only after the facade assigns it, so 'node_size' is not presented on any of them (§16.2b.3)
//! expect-check-fail: = help: state 'of Node' or 'of Leaf' on this fn item

// #3129 (§16.2b.3): two resources wrap one C type, so an operation on that
// type belongs to neither until the contract says which. The refusal lists
// both spellings.
use c_import("typedef struct node node;\nnode *node_new(void);\nvoid node_free(node *n);\nnode *leaf_new(void);\nvoid leaf_free(node *n);\nint node_size(node *n);\n")

c contract tree:
    resource Node wraps *mut node
        from node_new
        drop node_free
    resource Leaf wraps *mut node
        from leaf_new
        drop leaf_free
    fn node_size
        lend

fn main:
    print(1)
