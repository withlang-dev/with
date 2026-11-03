//! expect-stdout: 1 2
//! expect-stdout: ok

// #3019 (D122, D144, §16.2b.6): an imported record a facade hands out as a
// view is foreign memory whose identity is its address, so an unannotated
// `let` of the view keeps it a view even when the record is plain bits
// (`tnode { int tag; }`). D144's "a binding of plain bits takes the value"
// would have copied the node out, and the later `pick` would have handed C
// the address of the copy, with the result pinned to that local. The view
// keeps its document as its origin, so `either` can state `from d1, d2`.
use c_import("#include <stdlib.h>
typedef struct tnode { int tag; } tnode;
typedef struct tdoc { tnode *root; } tdoc;
static inline tdoc *tdoc_parse(int tag) { tdoc *d = (tdoc *)malloc(sizeof(tdoc)); tnode *r = (tnode *)malloc(sizeof(tnode)); r->tag = tag; d->root = r; return d; }
static inline void tdoc_free(tdoc *d) { free(d->root); free(d); }
static inline tnode *tdoc_root(tdoc *d) { return d->root; }
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
    fn tnode_pick
        returns borrow tnode from params 0, 1
        preserves param 0
        preserves param 1
    fn tnode_tag
        lend
        preserves param 0

fn either(d1: &Document, d2: &Document, which: i32) -> Option[&tnode] from d1, d2:
    let r1 = d1.root()?
    let r2 = d2.root()?
    r1.pick(r2, which)

fn main:
    let d1 = Document.parse(1).unwrap()
    let d2 = Document.parse(2).unwrap()
    print(f"{either(&d1, &d2, 0).unwrap().tag()} {either(&d1, &d2, 1).unwrap().tag()}")
    print("ok")
