//! expect-stdout: ok

use pre_d_build_runner
use std.fs

// A header's `static inline` definitions are that header's API: the unit
// of the same name publishes them once, includers import them instead of
// keeping private copies (TommyDS's tommy_hashdyn_search lives in
// tommyhashdyn.h; the facade calls it through std.tommyds.tommyhashdyn).
// A header no unit owns keeps a private copy per includer.
fn main:
    let case_dir = p7_prepare_case("migrate_header_inline_owner", "header_inline_owner_test")
    p7_write(case_dir, "source/engine.h", "typedef struct engine { int level; } engine;\nstatic inline int engine_peek(const engine *e) { return e->level * 2; }\nengine *engine_new(int level);\n")
    p7_write(case_dir, "source/util.h", "static inline int util_twice(int x) { return x + x; }\n")
    p7_write(case_dir, "source/engine.c", "#include <stdlib.h>\n#include \"engine.h\"\n#include \"util.h\"\nengine *engine_new(int level) { engine *e = malloc(sizeof(engine)); e->level = util_twice(level); return e; }\n")
    p7_write(case_dir, "source/user.c", "#include \"engine.h\"\n#include \"util.h\"\nint user_probe(void) { engine *e = engine_new(10); return engine_peek(e) + util_twice(1); }\n")
    let migrated = p7_run(case_dir, "header_inline_migrate", "migrate\0source\0--no-c-export\0-I\0source\0--shared-defs\0eng.defs\0-o\0lib/eng\0")
    p7_assert_success(migrated, "migrate a header-inline API owned by its unit")
    let engine = read_file(p7_join(case_dir, "lib/eng/engine.w")).unwrap()
    let user = read_file(p7_join(case_dir, "lib/eng/user.w")).unwrap()
    assert(engine.contains("pub unsafe fn engine_peek(") or engine.contains("pub fn engine_peek("))
    assert(not user.contains("fn engine_peek("))
    assert(user.contains("use eng.engine"))
    // util.h has no util.c: both units keep a private util_twice.
    assert(engine.contains("fn util_twice(") and not engine.contains("pub fn util_twice("))
    assert(user.contains("fn util_twice("))
    p7_write(case_dir, "src/main.w", "use eng.user\nfn main: assert(user_probe() == 42)\n")
    let executed = p7_run(case_dir, "header_inline_run", "run\0src/main.w\0")
    p7_assert_success(executed, "call the published inline through its owner")
    print("ok")
