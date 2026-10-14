//! expect-stdout: root 1
//! expect-stdout: child 2 next 3
//! expect-stdout: grandchild 4
//! expect-stdout: leaf none: true
//! expect-stdout: ok

// D122 (spec §16.2b.6): a borrow through a borrow is a borrow of the same
// origin. `xnode` is a record no resource wraps: `xdoc_root` lends it from the
// document, and `xnode_first_child` / `xnode_next` lend it from a node — so they
// are methods of the `&xnode` view, and a child taken through the root is
// borrowed from the document the root is borrowed from (one node type,
// always borrowed from the document). The walkers `preserves param 0`, so
// walking does not invalidate the other nodes in hand; the refused shapes
// are err_d122_child_outlives_document and err_d122_walk_invalidates_siblings.
use c_import("d122_tree.h")

c facade x:
    resource Document wraps *mut xdoc
        from xdoc_parse
        drop xdoc_free
    fn xdoc_root
        returns borrow xnode from param 0
        preserves param 0
    fn xnode_first_child
        returns borrow xnode from param 0
        preserves param 0
    fn xnode_next
        returns borrow xnode from param 0
        preserves param 0
    fn xnode_tag
        lend
        preserves param 0

fn main:
    let d = Document.parse("<a><b><d/></b><c/></a>").unwrap()
    let r = d.root().unwrap()
    print(f"root {r.tag()}")
    let c = r.first_child().unwrap()
    let s = c.next().unwrap()
    print(f"child {c.tag()} next {s.tag()}")
    let g = c.first_child().unwrap()
    print(f"grandchild {g.tag()}")
    print(f"leaf none: {g.first_child().is_none()}")
    print("ok")
