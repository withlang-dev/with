//! expect-stdout: doc 1: root 10, first 11, next 12
//! expect-stdout: owned 7: first 71
//! expect-stdout: ok

// D134 (§16.2b.6): a borrowed value's origin is the origin of the argument
// it was borrowed through, bound at each call, and one borrowed type serves
// every origin. `nd_first` borrows a `Node` from a `Node`; `dc_root` borrows
// a `Node` from a `Doc`. Before D134 the two items were refused together
// ("a borrowed value with several origin types is not ruled"); now a root
// taken from the document and a child taken from an owned node are both
// `BorrowedNode[_]`, each inside the life of what it was taken through.

use c_import("c_facade_tree.h")

c facade tree:
    resource Doc wraps *mut dc
        from dc_new
        drop dc_free
    resource Node wraps *mut nd
        from nd_new
        drop nd_free
    fn dc_root
        returns borrow Node from param 0
    fn nd_first
        returns borrow Node from param 0
    fn nd_next
        returns borrow Node from param 0
    fn nd_id
        lend
    fn nd_grow
        lend
    fn dc_id
        lend

fn main:
    let Some(d) = Doc.new(1) else:
        return 1
    let Some(root) = d.root() else:
        return 2
    let _ = root.grow(12)
    let _ = root.grow(11)
    let Some(first) = root.first() else:
        return 3
    let Some(next) = first.next() else:
        return 4
    print(f"doc {d.id()}: root {root.id()}, first {first.id()}, next {next.id()}")
    let Some(n) = Node.new(7) else:
        return 5
    let _ = n.grow(71)
    let Some(c) = n.first() else:
        return 6
    print(f"owned {n.id()}: first {c.id()}")
    print("ok")
