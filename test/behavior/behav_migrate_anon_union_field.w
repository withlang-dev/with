//! expect-stdout: ok

use pre_d_build_runner
use std.fs

// A struct's unnamed union member (zlib's `ct_data.fc`) is read and updated
// through the place: `s->tree[i].fc.freq++`. The union's libclang type is
// anonymous (translated `c_void`), so the emitter's borrow-through-type
// form cannot spell it; the plain `base.field` must be printed instead.
// (#1142 emitted `(*(&raw const ... as *const c_void)).freq`, which does
// not compile.)
fn main:
    let case_dir = p7_prepare_case("migrate_anon_union_field", "anon_union_field_test")
    p7_write(case_dir, "source/tree.h", "typedef struct ct_data_s { union { unsigned short freq; unsigned short code; } fc; union { unsigned short dad; unsigned short len; } dl; } ct_data;\ntypedef struct state_s { ct_data tree[4]; int total; } state;\nvoid bump(state *s, int i);\n")
    p7_write(case_dir, "source/tree.c", "#include \"tree.h\"\nvoid bump(state *s, int i) { s->tree[i].fc.freq++; s->tree[i].dl.len = s->tree[i].fc.freq + 1; s->total = s->tree[i].dl.len; }\n")
    let migrated = p7_run(case_dir, "anon_union_migrate", "migrate\0source\0--no-c-export\0-I\0source\0--shared-defs\0tr.defs\0-o\0lib/tr\0")
    p7_assert_success(migrated, "migrate an anonymous union member update")
    let tree = read_file(p7_join(case_dir, "lib/tr/tree.w")).unwrap()
    assert(not tree.contains("as *const c_void)).freq"))
    p7_write(case_dir, "src/main.w", "use tr.tree\nuse tr.defs\nfn main:\n    var s = state_s { tree: [ct_data_s { fc: ct_data_s_fc { freq: 0 }, dl: ct_data_s_dl { dad: 0 } }; 4], total: 0 }\n    unsafe { bump(&raw mut s, 2) }\n    unsafe { bump(&raw mut s, 2) }\n    assert(s.total == 3)\n")
    let executed = p7_run(case_dir, "anon_union_run", "run\0src/main.w\0")
    p7_assert_success(executed, "bump the union member twice")
    print("ok")
