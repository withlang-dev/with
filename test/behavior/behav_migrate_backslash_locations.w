//! expect-stdout: ok

use pre_d_build_runner
use std.fs

// The Clang bridge's path boundary: every location it hands the migrator is
// spelled with `/`, whatever Clang said. On Windows Clang spells locations
// with `\` (PR #1143 broke the header-owner pairing that way); on POSIX the
// same shape is reached by including a header through a name that carries a
// literal backslash. Either way the location's basename must be `engine.h`,
// so engine.c owns engine.h's inline and user.c imports it. A `\`-aware
// basename in the migrator would also pass the pairing, so the module path
// is asserted too: nothing downstream of the bridge may see a `\`.
fn main:
    let case_dir = p7_prepare_case("migrate_backslash_locations", "backslash_locations_test")
    // The directory exists for Windows (where `eng\engine.h` is eng/engine.h);
    // on POSIX the header is a file literally named `eng\engine.h`.
    p7_write(case_dir, "source/eng/README", "the engine header directory\n")
    p7_write(case_dir, "source/eng\\engine.h", "typedef struct engine { int level; } engine;\nstatic inline int engine_peek(const engine *e) { return e->level * 2; }\nengine *engine_new(int level);\n")
    p7_write(case_dir, "source/engine.c", "#include <stdlib.h>\n#include \"eng\\engine.h\"\nengine *engine_new(int level) { engine *e = malloc(sizeof(engine)); e->level = level + 1; return e; }\n")
    p7_write(case_dir, "source/user.c", "#include \"eng\\engine.h\"\nint user_probe(void) { engine *e = engine_new(10); return engine_peek(e) + 2; }\n")
    // The CLI paths carry a backslash too: they are rewritten once at entry.
    let migrated = p7_run(case_dir, "backslash_migrate", "migrate\0source\0--no-c-export\0-I\0source\0--shared-defs\0eng.defs\0-o\0lib\\eng\0")
    p7_assert_success(migrated, "migrate through a backslash include and a backslash output path")
    let engine = read_file(p7_join(case_dir, "lib/eng/engine.w")).unwrap()
    let user = read_file(p7_join(case_dir, "lib/eng/user.w")).unwrap()
    assert(engine.contains("pub unsafe fn engine_peek("))
    assert(not user.contains("fn engine_peek("))
    assert(user.contains("use eng.engine"))
    assert(not engine.contains("\\") and not user.contains("\\"))
    p7_write(case_dir, "src/main.w", "use eng.user\nfn main: assert(user_probe() == 24)\n")
    let executed = p7_run(case_dir, "backslash_run", "run\0src/main.w\0")
    p7_assert_success(executed, "call the published inline through its owner")
    print("ok")
