//! expect-contract: violations=0 ok
//! expect-contract: contract:libc@<toolchain facade libc>
//! expect-contract: uncited=0

// The toolchain's libc contract is a file of its own: its rows are placed
// in `<toolchain facade libc>`, at its own lines. They were placed in the
// importing file at those line numbers, so `strdup`'s claim was held cited
// or uncited by whatever this file has on its line 3. Its claims are no
// part of this file's uncited count: this file states two claims and cites
// both.
use c_import("typedef struct engine engine;
engine *engine_new(void);
void engine_free(engine *e);
char *strdup(const char *s);
void free(void *p);
")

c contract engine:
    // engine.h 2-3: made by engine_new, released by engine_free
    resource Engine wraps *mut engine
        from engine_new
        drop engine_free

fn main:
    let Some(e) = Engine.new() else:
        return
    print("made")
