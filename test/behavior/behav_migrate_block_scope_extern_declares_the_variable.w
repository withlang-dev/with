//! expect-stdout: ok
// C11 6.2.2p4: `extern T x;` in a function body declares the file-scope
// object `x`. Where the unit has no file-scope declaration of it (STC's
// `extern const uint8_t cutf8_dtab[];` inside an inline function, the table
// defined in another unit), that block declaration is the variable's
// declaration. The migrator refused the function as untranslatable ("names
// a variable no file-scope declaration in this translation unit gives a
// type") and the corpus could not be migrated (#3231).
use std.fs
use pre_d_build_runner

fn main:
    let root = p7_prepare_case("migrate_block_scope_extern", "blockextern")
    p7_write(root, "c/look.c", "#include <stdint.h>\nuint32_t look(uint32_t i) {\n    extern const uint8_t tab[];\n    return tab[i];\n}\nuint32_t look2(uint32_t i) {\n    extern const uint8_t tab[];\n    return tab[i] + 1u;\n}\n")
    p7_write(root, "c/tab.c", "#include <stdint.h>\nconst uint8_t tab[] = { 3, 5, 7 };\n")
    let migrated = p7_run(root, "migrate", p7_argv_append(p7_argv_append(p7_argv_append(p7_argv_append("", "migrate"), "c"), "-o"), "w"))
    let said = migrated.stdout ++ migrated.stderr
    if not said.contains("2/2 files, 2 functions translated"): print(said)
    p7_assert_success(migrated, "migrating a unit whose only declaration of a variable is a block-scope extern")
    assert(said.contains("2/2 files, 2 functions translated"))
    assert(not said.contains("untranslatable"))
    print("ok")
