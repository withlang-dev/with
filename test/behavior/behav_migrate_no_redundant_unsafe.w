//! expect-stdout: ok

use pre_d_build_runner
use std.fs

// A migrated function that touches raw pointers is an `unsafe fn`, so its
// body is already an unsafe context. The expression printer wrapped every raw
// operation in an `unsafe` prefix regardless (`(unsafe *p)`, `(unsafe v[i])`,
// `(unsafe *pt).x`), and the compiler warned "redundant unsafe prefix inside
// unsafe context" on each one: 15,750 warnings from the migrated corpora under
// lib/std on any program that loaded them. Inside an `unsafe fn` the printer
// keeps the parentheses and omits the prefix.
fn main:
    let case_dir = p7_prepare_case("migrate_no_redundant_unsafe", "no_redundant_unsafe_test")
    var unit = "struct pt { int x; int y; };\n"
    unit = unit ++ "int deref(const int *p) { return *p; }\n"
    unit = unit ++ "int sum(const int *v, int n) { int s = 0; for (int i = 0; i < n; i++) s += v[i]; return s; }\n"
    unit = unit ++ "int field(const struct pt *q) { return q->x * 10 + q->y; }\n"
    unit = unit ++ "void bump(struct pt *q) { q->x += 1; *(&q->y) += 2; }\n"
    p7_write(case_dir, "source/unit.c", unit)
    let migrated = p7_run(case_dir, "no_redundant_unsafe_migrate", "migrate\0source\0--no-c-export\0-I\0source\0--shared-defs\0ru.defs\0-o\0lib/ru\0")
    p7_assert_success(migrated, "migrate raw pointer operations")
    let migrated_unit = read_file(p7_join(case_dir, "lib/ru/unit.w")).unwrap()
    for name in ["deref", "sum", "field", "bump"]:
        assert(migrated_unit.contains("pub unsafe fn " ++ name ++ "("))
    // Every function of the unit is an `unsafe fn`, so no prefix survives.
    assert(not migrated_unit.contains("(unsafe "))
    assert(migrated_unit.contains("(*__param_p)"))
    assert(migrated_unit.contains("(__param_v[__local_i])"))
    assert(migrated_unit.contains("(*__param_q).x"))
    var main_text = "use ru.unit\nuse ru.defs\nfn main:\n"
    main_text = main_text ++ "    var held = pt { x: 5, y: 6 }\n"
    main_text = main_text ++ "    let a: [4]c_int = [1, 2, 3, 4]\n"
    main_text = main_text ++ "    unsafe:\n"
    main_text = main_text ++ "        bump(&raw mut held)\n"
    main_text = main_text ++ "        assert(deref(&raw const a[2]) == 3)\n"
    main_text = main_text ++ "        assert(sum(&raw const a[0], 4) == 10)\n"
    main_text = main_text ++ "        assert(field(&raw const held) == 68)\n"
    p7_write(case_dir, "src/main.w", main_text)
    let executed = p7_run(case_dir, "no_redundant_unsafe_run", "run\0src/main.w\0")
    p7_assert_success(executed, "run the migrated raw pointer operations")
    assert(not executed.stderr.contains("redundant unsafe prefix inside unsafe context\n --> lib/ru/"))
    print("ok")
