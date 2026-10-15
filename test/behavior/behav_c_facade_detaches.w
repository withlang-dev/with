//! expect-stdout: before: 2
//! expect-stdout: detached 12, left: 1
//! expect-stdout: ok

// D134 (§16.2b.6): `detaches param N` removes the value param N borrows
// from its origin and yields it as an owned `Detached<R>[Origin]`: its Drop
// runs the resource's destroyer (nd_free), it carries the resource's lends,
// and it holds a view of the origin it was taken out of, so it is destroyed
// before the document and cannot escape it (a `borrows` child's rules).
// The detaching call goes through the borrowed view, so the document's
// other views are invalidated by the default: the count is read afresh.

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
    fn nd_unlink
        detaches param 0
    fn nd_id
        lend
    fn nd_grow
        lend
    fn nd_count
        lend

fn main:
    let Some(d) = Doc.new(1) else:
        return 1
    let Some(root) = d.root() else:
        return 2
    let _ = root.grow(11)
    let _ = root.grow(12)
    print(f"before: {root.count()}")
    let Some(first) = root.first() else:
        return 3
    let taken = first.unlink()
    let Some(root_again) = d.root() else:
        return 4
    print(f"detached {taken.id()}, left: {root_again.count()}")
    print("ok")
