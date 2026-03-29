//! expect-stdout: ok

use regression_matrix.types

type LocalEntry {
    name: str,
    rank: i32,
}

type LocalBindings {
    entries: Vec[LocalEntry],
}

fn make_local_entries(name0: str, rank0: i32, name1: str, rank1: i32) -> Vec[LocalEntry]:
    let entries: Vec[LocalEntry] = Vec.new()
    entries.push(LocalEntry { name: name0, rank: rank0 })
    entries.push(LocalEntry { name: name1, rank: rank1 })
    entries

fn make_local_bindings(name0: str, rank0: i32, name1: str, rank1: i32) -> LocalBindings:
    LocalBindings { entries: make_local_entries(name0, rank0, name1, rank1) }

fn make_imported_entries(name0: str, rank0: i32, name1: str, rank1: i32) -> Vec[ImportedEntry]:
    let entries: Vec[ImportedEntry] = Vec.new()
    entries.push(ImportedEntry { name: name0, rank: rank0 })
    entries.push(ImportedEntry { name: name1, rank: rank1 })
    entries

fn make_imported_bindings(name0: str, rank0: i32, name1: str, rank1: i32) -> ImportedBindings:
    ImportedBindings { entries: make_imported_entries(name0, rank0, name1, rank1) }

fn local_vec_name_eq(entries: Vec[LocalEntry]) -> bool:
    entries[0].name == entries[1].name

fn local_vec_rank_eq(entries: Vec[LocalEntry]) -> bool:
    entries[0].rank == entries[1].rank

fn local_nested_name_eq(bindings: LocalBindings) -> bool:
    bindings.entries[0].name == bindings.entries[1].name

fn local_nested_rank_eq(bindings: LocalBindings) -> bool:
    bindings.entries[0].rank == bindings.entries[1].rank

fn local_loop_find_name(bindings: LocalBindings, target: str) -> bool:
    var i: i32 = 0
    while i < bindings.entries.len() as i32:
        if bindings.entries[i].name == target:
            return true
        i = i + 1
    false

fn local_loop_find_rank(bindings: LocalBindings, target: i32) -> bool:
    var i: i32 = 0
    while i < bindings.entries.len() as i32:
        if bindings.entries[i].rank == target:
            return true
        i = i + 1
    false

fn imported_vec_name_eq(entries: Vec[ImportedEntry]) -> bool:
    entries[0].name == entries[1].name

fn imported_vec_rank_eq(entries: Vec[ImportedEntry]) -> bool:
    entries[0].rank == entries[1].rank

fn imported_nested_name_eq(bindings: ImportedBindings) -> bool:
    bindings.entries[0].name == bindings.entries[1].name

fn imported_nested_rank_eq(bindings: ImportedBindings) -> bool:
    bindings.entries[0].rank == bindings.entries[1].rank

fn imported_loop_find_name(bindings: ImportedBindings, target: str) -> bool:
    var i: i32 = 0
    while i < bindings.entries.len() as i32:
        if bindings.entries[i].name == target:
            return true
        i = i + 1
    false

fn imported_loop_find_rank(bindings: ImportedBindings, target: i32) -> bool:
    var i: i32 = 0
    while i < bindings.entries.len() as i32:
        if bindings.entries[i].rank == target:
            return true
        i = i + 1
    false

fn test_local_projection_matrix:
    assert(local_vec_name_eq(make_local_entries("same", 1, "same", 2)))
    assert(not local_vec_name_eq(make_local_entries("left", 1, "right", 2)))
    assert(local_vec_rank_eq(make_local_entries("left", 7, "right", 7)))
    assert(not local_vec_rank_eq(make_local_entries("left", 7, "right", 8)))

    assert(local_nested_name_eq(make_local_bindings("same", 1, "same", 2)))
    assert(not local_nested_name_eq(make_local_bindings("left", 1, "right", 2)))
    assert(local_nested_rank_eq(make_local_bindings("left", 9, "right", 9)))
    assert(not local_nested_rank_eq(make_local_bindings("left", 9, "right", 10)))

    assert(local_loop_find_name(make_local_bindings("lhs", 1, "target", 2), "target"))
    assert(not local_loop_find_name(make_local_bindings("lhs", 1, "rhs", 2), "target"))
    assert(local_loop_find_rank(make_local_bindings("lhs", 1, "rhs", 22), 22))
    assert(not local_loop_find_rank(make_local_bindings("lhs", 1, "rhs", 22), 99))

fn test_imported_projection_matrix:
    assert(imported_vec_name_eq(make_imported_entries("same", 1, "same", 2)))
    assert(not imported_vec_name_eq(make_imported_entries("left", 1, "right", 2)))
    assert(imported_vec_rank_eq(make_imported_entries("left", 7, "right", 7)))
    assert(not imported_vec_rank_eq(make_imported_entries("left", 7, "right", 8)))

    assert(imported_nested_name_eq(make_imported_bindings("same", 1, "same", 2)))
    assert(not imported_nested_name_eq(make_imported_bindings("left", 1, "right", 2)))
    assert(imported_nested_rank_eq(make_imported_bindings("left", 9, "right", 9)))
    assert(not imported_nested_rank_eq(make_imported_bindings("left", 9, "right", 10)))

    assert(imported_loop_find_name(make_imported_bindings("lhs", 1, "target", 2), "target"))
    assert(not imported_loop_find_name(make_imported_bindings("lhs", 1, "rhs", 2), "target"))
    assert(imported_loop_find_rank(make_imported_bindings("lhs", 1, "rhs", 22), 22))
    assert(not imported_loop_find_rank(make_imported_bindings("lhs", 1, "rhs", 22), 99))

fn main:
    test_local_projection_matrix()
    test_imported_projection_matrix()
    println("ok")
