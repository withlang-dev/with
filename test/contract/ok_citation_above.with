//! expect-contract: violations=0 ok
//! expect-contract: stated=5 registry=0 profile=0 annotation=0 uncited=1

// §31.9 rule 2: a comment directly above an `fn` or `resource` line cites
// it, as a comment on the line does (Eric, 2026-11-14). The resource and
// `engine_peek` are cited from above; a blank line parts `engine_name` from
// the comment before it, so it is the one uncited claim.
use c_import("typedef struct engine engine;
engine *engine_new(void);
void engine_free(engine *e);
int engine_peek(engine *e);
int engine_name(engine *e);
")

c contract engine:
    // engine.h 2-3: made by engine_new, released by engine_free
    resource Engine wraps *mut engine
        from engine_new
        drop engine_free
    // engine.c, engine_peek: reads the count
    // and keeps nothing
    fn engine_peek
    // engine.c, engine_name: not this function's citation

    fn engine_name

fn main:
    let Some(e) = Engine.new() else:
        return
    print(e.peek() + e.name())
