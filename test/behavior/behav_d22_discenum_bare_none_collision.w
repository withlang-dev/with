//! expect-stdout: ok
// D22 acceptance cell, promoted 2026-10-18. D22 discriminants must be enum-scoped; a repr enum's
// bare `None = k` must not poison Option.None (accessor, match, guards).

use std.collections.HashMap
enum Junk: i32:
    None = 3
    Blah = 5

type Gizmo {
    mir_local_types: HashMap[i32, i64],
    mir_indirect_value_local_types: HashMap[i32, i64],
    builder: i64,
}

fn wl_fake_load(b: i64, ty: i64, p: i64) -> i64: b + ty + p

fn take_match(o: Option[&i64]) -> i64:
    match o:
        Some(v) => v
        None => -1

fn junk_code(j: Junk) -> i64:
    match j:
        Junk.None => 31
        Junk.Blah => 51

impl Gizmo:
    fn probe(local_id: i32, storage_ptr: i64) -> i64:
        if storage_ptr == 0:
            return 0
        if self.mir_indirect_value_local_types.get(local_id).is_none():
            return 0
        let ptr_ty_opt = self.mir_local_types.get(local_id)
        if ptr_ty_opt.is_none():
            return 0
        let ptr_ty = ptr_ty_opt.unwrap() as i64
        if ptr_ty == 0 or ptr_ty == 77:
            return 0
        wl_fake_load(self.builder, ptr_ty, storage_ptr)

fn main:
    var g = Gizmo { mir_local_types: HashMap.new(), mir_indirect_value_local_types: HashMap.new(), builder: 1000 }
    g.mir_local_types.insert(1, 100)
    g.mir_indirect_value_local_types.insert(1, 200)
    g.mir_local_types.insert(2, 300)
    g.mir_local_types.insert(4, 77)
    g.mir_indirect_value_local_types.insert(4, 400)
    assert(g.probe(1, 5) == 1105)
    assert(g.probe(2, 5) == 0)
    assert(g.probe(3, 5) == 0)
    assert(g.probe(1, 0) == 0)
    assert(g.probe(4, 5) == 0)

    assert(g.mir_local_types.get(1).is_some())
    assert(not g.mir_local_types.get(1).is_none())
    assert(g.mir_local_types.get(9).is_none())
    assert(not g.mir_local_types.get(9).is_some())

    assert(take_match(g.mir_local_types.get(1)) == 100)
    assert(take_match(g.mir_local_types.get(9)) == -1)

    assert(junk_code(Junk.None) == 31)
    assert(junk_code(Junk.Blah) == 51)
    print("ok")
