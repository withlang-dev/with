//! expect-stdout: same

// #2043: `typedef struct node node;` over an incomplete struct declares ONE
// opaque type. c_import emitted `type node = opaque` twice (the struct's
// forward declaration and the typedef), Sema made two types of one name,
// and `struct_node` (the struct's alias) named the first while `node` named
// the second: a `*mut struct_node` was not a `*mut node`, and codegen's AST
// resolution of the alias disagreed with Sema's (audit:codegen).
use c_import("typedef struct node node;\nstruct node *node_next(struct node *n);\nint node_len(node *n);\n")

fn same(p: *mut struct_node) -> *mut node: p

fn main:
    let p: *mut node = null
    if same(p) == null: print("same")
