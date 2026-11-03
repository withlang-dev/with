//! expect-stdout: pick 0: 1
//! expect-stdout: pick 1: 2
//! expect-stdout: same doc: 11
//! expect-stdout: ok

// D187 (spec §16.2b.6): `returns borrow T from params N, M` — an operation
// whose returned pointer is a part of either of two parameters hands out a
// view of both origins at each call: it lives no longer than the shorter and
// is invalidated when either origin's views are. `tnode_pick` answers one
// of its two node arguments; a node is a record borrowed from its document
// (D122), so the pick is a view of both documents. The refused shape is
// err_d187_two_origin_view_outlives_one.
use c_import("#include <stdlib.h>
typedef struct tnode { struct tnode *first; int tag; } tnode;
typedef struct tdoc { tnode *root; } tdoc;
static inline tdoc *tdoc_parse(int tag) { tdoc *d = (tdoc *)malloc(sizeof(tdoc)); tnode *r = (tnode *)malloc(sizeof(tnode)); tnode *c = (tnode *)malloc(sizeof(tnode)); c->first = 0; c->tag = tag * 10 + 1; r->first = c; r->tag = tag; d->root = r; return d; }
static inline void tdoc_free(tdoc *d) { free(d->root->first); free(d->root); free(d); }
static inline tnode *tdoc_root(tdoc *d) { return d->root; }
static inline tnode *tnode_first_child(tnode *n) { return n->first; }
static inline tnode *tnode_pick(tnode *a, tnode *b, int which) { return which ? b : a; }
static inline int tnode_tag(const tnode *n) { return n->tag; }
")

c facade pk:
    resource Document wraps *mut tdoc
        from tdoc_parse
        drop tdoc_free
    fn tdoc_root
        returns borrow tnode from param 0
        preserves param 0
    fn tnode_first_child
        returns borrow tnode from param 0
        preserves param 0
    fn tnode_pick
        returns borrow tnode from params 0, 1
        preserves param 0
        preserves param 1
    fn tnode_tag
        lend
        preserves param 0

// A function handing the pick on states both origins, as the clause does.
fn either(a: &tnode, b: &tnode, which: i32) -> Option[&tnode] from a, b:
    a.pick(b, which)

// Two nodes of one document: the pick is a view of that document alone
// (both arguments view `d`; the second adds no new origin, and is not
// itself one).
fn same_doc(d: &Document) -> Option[&tnode] from d:
    let r = d.root()?
    let c = r.first_child()?
    r.pick(c, 1)

fn main:
    let d1 = Document.parse(1).unwrap()
    let d2 = Document.parse(2).unwrap()
    let r1 = d1.root().unwrap()
    let r2 = d2.root().unwrap()
    print(f"pick 0: {either(r1, r2, 0).unwrap().tag()}")
    print(f"pick 1: {r1.pick(r2, 1).unwrap().tag()}")
    print(f"same doc: {same_doc(&d1).unwrap().tag()}")
    print("ok")
