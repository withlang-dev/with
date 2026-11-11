//! expect-check-fail: unknown field 'n' for type 'Box2'
// D198 (§16.2b.3): reading through a pointer resource is a claim about C's memory; it is not read through the resource.
use c_import("#include <stdlib.h>\ntypedef struct box { int n; } box; static inline box *box_new(void) { box *b = malloc(sizeof(box)); b->n = 4; return b; } static inline void box_free(box *b) { free(b); }")

c contract boxes:
    resource Box2 wraps *mut box
        from box_new
        drop box_free

fn main:
    let Some(b) = Box2.new() else: return
    print(f"{b.n}")
