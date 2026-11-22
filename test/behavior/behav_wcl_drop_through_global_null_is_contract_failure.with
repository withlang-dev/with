//! expect-exit: 134
//! expect-stdout: made
//! expect-stderr: Engine: 'drop engine_release', but engine_release is NULL

// §31.8.6, §31.11: the generated code never calls a null pointer. Before
// the call a `drop` makes through a function-pointer global it tests the
// pointer it read; NULL is a contract failure naming the clause and the
// global.
use c_import("typedef struct engine { int n; } engine;
typedef void (*engine_free_fn)(engine *e);
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
