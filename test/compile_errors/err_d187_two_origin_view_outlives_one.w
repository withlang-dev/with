//! expect-check-fail: `pick_first` returns a view derived from `b`, which its `from` clause does not name

// D187 (spec §16.2b.6): a view borrowed from two parameters is a view of
// both origins. `tnode_pick` states `from params 0, 1`, so a function
// returning its result as a view of the first node alone is refused: the
// result may be the second's, and the clause states every origin.
use c_import("#include <stdlib.h>
typedef struct tnode { struct tnode *first; int tag; } tnode;
typedef struct tdoc { tnode *root; } tdoc;
static inline tdoc *tdoc_parse(int tag) { tdoc *d = (tdoc *)malloc(sizeof(tdoc)); tnode *r = (tnode *)malloc(sizeof(tnode)); r->first = 0; r->tag = tag; d->root = r; return d; }
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

fn pick_first(a: &tnode, b: &tnode) -> Option[&tnode] from a:
    a.pick(b, 0)

fn main:
    let d1 = Document.parse(1).unwrap()
    let d2 = Document.parse(2).unwrap()
    print(f"{pick_first(d1.root().unwrap(), d2.root().unwrap()).unwrap().tag()}")
