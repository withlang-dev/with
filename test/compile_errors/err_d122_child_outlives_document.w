//! expect-check-fail: returned view may outlive its origin 'd'

// D122 (spec §16.2b.6): a borrow through a borrow is a borrow of the same
// origin. The child is taken through the root, and the root from the
// document, so the child cannot outlive the document either.
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

fn child() -> &xnode:
    let d = Document.parse("<a><b/></a>").unwrap()
    let r = d.root().unwrap()
    r.first_child().unwrap()

fn main:
    print(f"{child().tag}")
