//! expect-check-fail: view `r` borrows from `d`, which `xnode_next` may have invalidated (§16.2b.7)

// D122 (spec §16.2b.6): every operation through a node is an operation on
// the document it is borrowed from. `xnode_next` states no preservation, so
// (§16.2b.7: unknown effect means invalidate) calling it through `c`
// invalidates every view of the document, the root in hand included.
use c_import("../behavior/d122_tree.h")

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

fn main:
    let d = Document.parse("<a><b/><c/></a>").unwrap()
    let r = d.root().unwrap()
    let c = r.first_child().unwrap()
    let s = c.next().unwrap()
    print(f"{r.tag} {s.tag}")
