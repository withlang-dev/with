//! expect-check-fail: 'drop engine_release' names a global that does not hold a function of one parameter taking the pointer the resource wraps

// §31.8.6: the global a `drop` names holds the function that releases the
// resource: one parameter, the pointer the resource wraps. This one takes
// an int.
use c_import("typedef struct engine { int n; } engine;
typedef void (*engine_free_fn)(int which);
static engine lib_engine;
static engine_free_fn engine_release = 0;
static inline engine *engine_new(void) { return &lib_engine; }
")

c contract engine:
    resource Engine wraps *mut engine
        from engine_new
        drop engine_release

fn main:
    let Some(e) = Engine.new() else:
        return
    print("made")
