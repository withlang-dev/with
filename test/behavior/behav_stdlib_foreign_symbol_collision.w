//! expect-stdout: ok
use pre_d_build_runner

fn main:
    let root = p7_prepare_case("stdlib_foreign_symbol_collision", "stdlibcollision")
    // Model a foreign archive's implementation-only symbol without any C
    // source. The application imports only the archive's public entry point.
    p7_write(root, "src/library.w", "@[c_export(\"to_lower\")]\nfn foreign_lower(c: i32) -> i32: c + 1000\n@[c_export(\"foreign_lower_entry\")]\nfn entry(c: i32) -> i32: foreign_lower(c)\n")
    p7_write(root, "src/main.w", "use std.re.defs.{to_lower}\nextern fn foreign_lower_entry(c: i32) -> i32\nfn main:\n    assert(to_lower(65) == 97)\n    assert(unsafe { foreign_lower_entry(65) } == 1065)\n    print(\"both lower functions work\")\n")
    p7_write(root, "build.w", "use std.build\npub fn build(ctx: BuildCtx) -> Build:\n    let native = target_new(.Archive, \"native\", \"src/library.w\").output(\"native/liblower.a\")\n    let app = target_new(.Executable, \"app\", \"src/main.w\").library_path(\"native\").link_system_lib(\"lower\").output(\"out/app\").dep(\"native\")\n    ctx.new_build().add_target(native).add_target(app).default(\"app\")\n")
    let result = p7_run(root, "stdlib-foreign-collision", "run\0:app\0")
    p7_assert_success(result, "stdlib functions cannot collide with a foreign archive's private implementation")
    assert(result.stdout.contains("both lower functions work"))
    print("ok")
