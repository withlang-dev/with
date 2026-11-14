//! expect-contract: violations=0 ok
//! expect-contract: stated=5 registry=0 profile=0 annotation=0 uncited=1

// §31.9 rule 2: a citation on an `fn` or `resource` line covers the clauses
// under it that carry none. The resource's line covers its `from` and its
// `drop`; `engine_peek` is cited on its own line; `engine_name` is not, and
// is the one uncited claim.
use c_import("typedef struct engine engine;
engine *engine_new(void);
void engine_free(engine *e);
int engine_peek(engine *e);
int engine_name(engine *e);
")

c contract engine:
    resource Engine wraps *mut engine    // engine.h 2-3: made by engine_new, released by engine_free
        from engine_new
        drop engine_free
    fn engine_peek    // engine.c, engine_peek: reads the count and keeps nothing
    fn engine_name

fn main:
    let Some(e) = Engine.new() else:
        return
    print(e.peek() + e.name())
