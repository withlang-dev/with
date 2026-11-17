//! expect-check-fail: 'lib_use_other' assigns 'engine_release', the global a destroyer clause names: a function that assigns it stays raw, and a contract cannot describe it
//! expect-check-fail: 'lib_reset' assigns 'engine_release', the global a destroyer clause names
//! expect-check-fail: = help: delete the 'fn lib_use_other' item

// §31.8.6: a function that assigns the global a `drop` names stays raw
// whatever a contract says of its parameters: nothing safe code can call
// writes the pointer the generated call reads. A contract that describes
// one is an error. `lib_reset` assigns it through the function it calls.
use c_import("typedef struct engine { int n; } engine;
typedef void (*engine_free_fn)(engine *e);
static engine lib_engine;
static inline void lib_release_first(engine *e) { }
static inline void lib_release_second(engine *e) { }
static engine_free_fn engine_release = lib_release_first;
static inline void lib_use_other(engine *e) { engine_release = lib_release_second; }
static inline void lib_reset(engine *e) { lib_use_other(e); }
static inline engine *engine_new(void) { return &lib_engine; }
")

c contract engine:
    resource Engine wraps *mut engine
        from engine_new
        drop engine_release
    fn lib_use_other
    fn lib_reset

fn main:
    let Some(e) = Engine.new() else:
        return
    e.lib_use_other()
    e.lib_reset()
