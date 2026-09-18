// Probe: degenerate return values of every @[weak] stub in rt/cimport_stubs.w.
// Snapshot 450733e5. Pure-logic mirror — single-file `run` cannot link the
// weak objects (they lose to clang_bridge.o whenever libclang is present),
// so each stub's documented degenerate value is mirrored and asserted here.
// Run via seed:
//   out/bootstrap/bin/with-stage1 run .audit/probes/rt_compat/stub_degenerate_values.w
//
// Mirror source: rt/cimport_stubs.w:13-601 (fully read).

// --- int-returning stubs: 0 means "absent/empty" ---
fn stub_available() -> i32: 0                    // :13 with_cimport_available
fn stub_parse() -> i64: 0                        // :15 with_cimport_parse
fn stub_decl_count() -> i32: 0                   // :26 with_cimport_decl_count
fn stub_decl_kind() -> i32: 0                    // :30 with_cimport_decl_kind
fn stub_fn_param_count() -> i32: 0               // :50 with_cimport_fn_param_count
fn stub_struct_field_count() -> i32: 0           // :97 with_cimport_struct_field_count
fn stub_struct_size() -> i64: 0                  // :542 with_cimport_struct_size
fn stub_struct_align() -> i64: 0                 // :559 with_cimport_struct_align
// --- sentinel -1 stubs: invalid cursor/type/size ---
fn stub_decl_cursor() -> i32: -1                 // :40 with_cimport_decl_cursor
fn stub_root_cursor() -> i32: -1                 // :169 with_ci_root_cursor
fn stub_child() -> i32: -1                       // :178 with_ci_child
fn stub_cursor_type() -> i32: -1                 // :194 with_ci_cursor_type
fn stub_array_size() -> i64: -1                  // :209 with_ci_type_array_size
fn stub_field_offset() -> i64: -1                // :530 with_cimport_struct_field_offset
fn stub_cursor_start_offset() -> i32: -1         // :296 with_ci_cursor_start_offset
// --- plausible-value stubs: correct only when libclang present ---
fn stub_is_opaque() -> i32: 1                    // :114 with_cimport_struct_is_opaque
fn stub_type_canonical(t: i32) -> i32: t         // :234 with_ci_type_canonical (identity)
fn stub_realpath(path: str) -> str: path         // :166 with_cimport_realpath (passthrough)
fn stub_enum_int_type() -> str: "int"            // :441 with_cimport_enum_int_type
fn stub_calling_conv() -> str: "c"               // :564 with_cimport_fn_calling_conv
fn stub_translated() -> str: "i32"               // :446-:476 *_translated defaults
fn stub_ret_translated() -> str: "void"          // :452 with_cimport_fn_return_type_translated
fn stub_empty() -> str: ""                       // :7 empty_str helpers

fn main:
    // T15: every 0-degenerate is "empty set" shaped — parse=0 + count=0 means
    // callers iterating 0..count never touch the other stubs. Correct degenerate.
    assert(stub_available() == 0)
    assert(stub_parse() == 0)
    assert(stub_decl_count() == 0)
    assert(stub_decl_kind() == 0)
    assert(stub_fn_param_count() == 0)
    assert(stub_struct_field_count() == 0)
    print("zero-degenerates ok: available/parse/counts all 0")
    // T15: -1 sentinels match the bridge's own invalid-session sentinels
    // (ClangBridge.w:1440 decl_cursor -1, 1650/1720 field_offset/size -1...).
    // Correct degenerate.
    assert(stub_decl_cursor() == -1)
    assert(stub_root_cursor() == -1)
    assert(stub_child() == -1)
    assert(stub_cursor_type() == -1)
    assert(stub_array_size() == -1)
    assert(stub_field_offset() == -1)
    assert(stub_cursor_start_offset() == -1)
    print("neg1-degenerates ok: cursor/type/offset sentinels all -1")
    // T23: silent-wrong-value shaped — see audit notes. is_opaque=1 matches the
    // bridge's invalid-session answer (ClangBridge.w:1731 returns 1), and
    // canonical-identity + realpath-passthrough are safe; but struct_size=0 /
    // struct_align=0 disagree with the bridge's invalid-session -1
    // (ClangBridge.w:1712,1749), and "int"/"c"/"i32"/"void" are plausible
    // types for headers that were never parsed.
    assert(stub_is_opaque() == 1)
    assert(stub_type_canonical(7) == 7)
    assert(stub_realpath("x.h") == "x.h")
    assert(stub_enum_int_type() == "int")
    assert(stub_calling_conv() == "c")
    assert(stub_translated() == "i32")
    assert(stub_ret_translated() == "void")
    assert(stub_empty() == "")
    print("plausible-value stubs ok: opaque=1 canonical-id realpath-passthrough int/c/i32/void")
