//! expect-stdout: ok

// #1396: member records with no name held through an array or pointer, tags
// declared inside a record, and layouts With cannot spell (bitfields, fields
// under their natural alignment) import as C declares them or opaque; before,
// the array field was `c_void`, the nested union an unknown type, and the
// pack(2) record an `@[align(2)]` under the natural alignment — the import
// failed to compile.

use c_import("behav_c_import_nested_records.h")

fn main:
    let rec = nr_scope_ScopeRecord { Begin: 1, End: 2 }
    assert(rec.End == 2)
    assert(sizeof[nr_scope]() == 12)
    assert(sizeof[nr_hold_grid]() == 2)
    assert(sizeof[nr_hold]() == 32)
    let held = nr_hold_inner { tag: 7, next: null }
    assert(held.tag == 7)
    let next: *mut nr_hold_inner_next = held.next
    assert(next == null)
    let u = nr_handle_u { in_proc: 5 }
    let h = nr_handle { ctx: 1, u: u, kind: NR_KIND_B as i32 }
    assert(h.kind == 4)
    assert(NR_KIND_A == 3)
    let bits: *mut nr_bits = null
    let inner_bits: *mut nr_inner_bits = null
    let packed: *mut nr_packed2 = null
    assert(bits == null and inner_bits == null and packed == null)
    print("ok")
