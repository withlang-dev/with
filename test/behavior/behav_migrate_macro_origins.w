//! expect-stdout: ok

// #1102: macro values remain available for expansion, but host headers and
// the generated preprocessing driver do not become migrated public APIs.
use pre_d_build_runner
use std.fs

fn main:
    let case_dir = p7_prepare_case("migrate_macro_origins", "macro_origins")
    p7_write(case_dir, "input/SDKs/Fake.sdk/usr/include/system.h", "#define HOST_SDK_CONSTANT 43\n#define HOST_SDK_ADD(x) ((x) + HOST_SDK_CONSTANT)\n#define HOST_ALIAS HOST_SDK_ADD\n#define HOST_UNPAREN(x) x + 1\n#define HOST_COMPOUND (-2147483647 - 1)\n#define HOST_SUB(x, y) ((x) - (y))\n")
    let project_macros = "#define PROJECT_HEADER 3\n#define PROJECT_ALIAS HOST_SDK_CONSTANT\n#define PROJECT_ADD(x) ((x) + HOST_SDK_CONSTANT)\n#define PROJECT_WRAP(x) HOST_SDK_ADD(x)\n#define PROJECT_ALIAS_CALL(x) HOST_ALIAS(x)\n#define PROJECT_PRECEDENCE(x) (3 * HOST_UNPAREN(x))\n#define PROJECT_COMPOUND(x) ((x) + HOST_COMPOUND)\n#define PROJECT_NESTED(x) HOST_SDK_ADD(HOST_SDK_ADD(x))\n#define PROJECT_SWAPPED(x, y) HOST_SUB(y, x)\n#define PROJECT_CALLABLE_ALIAS HOST_ALIAS\n"
    p7_write(case_dir, "input/project.h", project_macros)
    p7_write(case_dir, "input/unit.c", "#include \"SDKs/Fake.sdk/usr/include/system.h\"\n#include \"project.h\"\n#define PROJECT_CONSTANT 7\nint value(void) { return HOST_SDK_ADD(PROJECT_CONSTANT) + PROJECT_HEADER; }\n")
    let migrated = p7_run(case_dir, "macro_origins_migrate", "migrate\0input\0--shared-defs\0sample.defs\0--no-c-export\0-o\0lib/sample\0")
    p7_assert_success(migrated, "migrate macro origins")
    let defs = read_file(p7_join(case_dir, "lib/sample/defs.w")).unwrap()
    assert(not defs.contains("HOST_SDK_CONSTANT"))
    assert(not defs.contains("HOST_SDK_ADD"))
    assert(not defs.contains("HAVE_UNISTD_H"))
    assert(not defs.contains("MAC_OS_X_VERSION_"))
    assert(defs.contains("PROJECT_HEADER"))
    assert(defs.contains("PROJECT_ALIAS"))
    assert(defs.contains("PROJECT_CONSTANT"))
    assert(defs.contains("PROJECT_ADD"))
    assert(defs.contains("PROJECT_WRAP"))
    p7_write(case_dir, "src/main.w", "use sample.unit\nuse sample.defs\nfn main:\n    assert(value() == 53)\n    assert(PROJECT_ALIAS == 43)\n    assert(PROJECT_ADD(7) == 50)\n    assert(PROJECT_WRAP(8) == 51)\n    assert(PROJECT_ALIAS_CALL(8) == 51)\n    assert(PROJECT_PRECEDENCE(2) == 7)\n    assert(PROJECT_COMPOUND(2147483647) == -1)\n    assert(PROJECT_NESTED(1) == 87)\n    assert(PROJECT_SWAPPED(2, 7) == 5)\n    assert(PROJECT_CALLABLE_ALIAS(8) == 51)\n    print(\"migrated ok\")\n")
    let executed = p7_run(case_dir, "macro_origins_run", "run\0src/main.w\0")
    p7_assert_success(executed, "execute migrated macro expansion")
    assert(executed.stdout.contains("migrated ok"))

    // The same name is public when the corpus itself defines it. Origin,
    // rather than a list of host macro names, controls declaration emission.
    p7_write(case_dir, "input/project.h", "#undef HAVE_UNISTD_H\n#define HAVE_UNISTD_H 0\n" ++ project_macros)
    let redefined = p7_run(case_dir, "macro_origins_redefined", "migrate\0input\0--shared-defs\0sample.defs\0--no-c-export\0-o\0lib/sample\0")
    p7_assert_success(redefined, "migrate project redefinition")
    p7_assert_file_contains(case_dir, "lib/sample/defs.w", "pub let HAVE_UNISTD_H: c_int = 0")

    // c_import intentionally exposes the requested header and inline macros.
    let header = p7_join(case_dir, "input/SDKs/Fake.sdk/usr/include/system.h")
    p7_write(case_dir, "src/import.w", "use c_import(\"#include \\\"" ++ header ++ "\\\"\\n#define INLINE_CONSTANT 5\\n\")\nfn main:\n    assert(HOST_SDK_CONSTANT == 43)\n    assert(HOST_SDK_ADD(INLINE_CONSTANT) == 48)\n    assert(HOST_ALIAS(INLINE_CONSTANT) == 48)\n    print(\"import ok\")\n")
    let imported = p7_run(case_dir, "macro_origins_import", "run\0src/import.w\0")
    p7_assert_success(imported, "c_import retains requested macros")
    assert(imported.stdout.contains("import ok"))
    print("ok")
