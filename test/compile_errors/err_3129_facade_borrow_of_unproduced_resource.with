//! expect-check-fail: fn 'node_child': 'returns borrow Node' borrows a resource that states no producer and no 'drop', so 'Node' has no presented type to borrow (§16.2b.3, §16.2b.6)
//! expect-check-fail: = help: state how a 'Node' is produced and destroyed ('from <fn>' and 'drop <fn>') on the resource; a resource that is only ever borrowed is not modeled yet

// #3129 (§16.2b.3, §16.2b.6): a resource that is only ever borrowed has no presented type.
use c_import("typedef struct node node;\nnode *node_new(void);\nvoid node_free(node *n);\nnode *node_child(node *n, int i);\nconst char *node_text(node *n, int k);\nnode *node_at(int i, node *n);\n")

c contract tree:
    resource Node wraps *mut node
    fn node_child
        returns borrow Node from param 0

fn main:
    print(1)
