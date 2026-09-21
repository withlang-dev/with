//! expect-stdout: ok

use pre_d_build_runner
use std.fs

// Unary `*` on an array is its first element: C decays the operand to a
// pointer before the dereference. The migrator dereferenced the array value
// itself (`*__local_header`, "cannot dereference non-pointer value"), which
// minizip's mztools reaches through `#define READ_8(adr) ((unsigned char)*(adr))`
// over `char header[30]`. Every shape of the operand is one rule: a local, a
// parenthesised local, a macro argument, a struct field, an array of arrays
// dereferenced twice, and a store through it. An array-spelled parameter
// (`int v[4]`) is a pointer already and stays as written.
fn main:
    let case_dir = p7_prepare_case("migrate_deref_of_array", "deref_of_array_test")
    var unit = "#define READ_8(adr) ((unsigned char)*(adr))\n"
    unit = unit ++ "struct holder { char f[4]; };\n"
    unit = unit ++ "int plain(void) { char h[4]; h[0] = 7; return *h; }\n"
    unit = unit ++ "int paren(void) { char h[4]; h[0] = 8; return *(h); }\n"
    unit = unit ++ "int through_macro(void) { char h[4]; h[0] = 9; return READ_8(h); }\n"
    unit = unit ++ "int field(struct holder *p) { return *p->f; }\n"
    unit = unit ++ "int twice(void) { int m[2][2]; m[0][0] = 11; return **m; }\n"
    unit = unit ++ "int stores(void) { int a[3]; *a = 12; return a[0]; }\n"
    unit = unit ++ "int through_param(int v[4]) { return *v; }\n"
    unit = unit ++ "int calls(void) { int a[4]; a[0] = 13; return through_param(a); }\n"
    p7_write(case_dir, "source/unit.c", unit)
    let migrated = p7_run(case_dir, "deref_of_array_migrate", "migrate\0source\0--no-c-export\0-I\0source\0--shared-defs\0da.defs\0-o\0lib/da\0")
    p7_assert_success(migrated, "migrate a dereference of an array")
    // An array-spelled parameter is a pointer in the signature (it was the
    // by-value `[4]c_int`, which no caller's decayed argument fits), so
    // there is nothing to decay at its dereference.
    let migrated_unit = read_file(p7_join(case_dir, "lib/da/unit.w")).unwrap()
    assert(migrated_unit.contains("__param_v: *mut c_int"))
    assert(not migrated_unit.contains("__param_v[0]"))
    var main_text = "use da.unit\nuse da.defs\nfn main:\n"
    main_text = main_text ++ "    var held = holder { f: [10 as c_char; 4] }\n"
    main_text = main_text ++ "    unsafe:\n"
    main_text = main_text ++ "        assert(plain() == 7)\n"
    main_text = main_text ++ "        assert(paren() == 8)\n"
    main_text = main_text ++ "        assert(through_macro() == 9)\n"
    main_text = main_text ++ "        assert(field(&raw mut held) == 10)\n"
    main_text = main_text ++ "        assert(twice() == 11)\n"
    main_text = main_text ++ "        assert(stores() == 12)\n"
    main_text = main_text ++ "        assert(calls() == 13)\n"
    p7_write(case_dir, "src/main.w", main_text)
    let executed = p7_run(case_dir, "deref_of_array_run", "run\0src/main.w\0")
    p7_assert_success(executed, "run the migrated dereferences")
    print("ok")
