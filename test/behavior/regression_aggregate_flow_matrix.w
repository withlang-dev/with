//! expect-stdout: ok

use regression_matrix.types

type LocalEntry {
    name: str,
    rank: i32,
}

error LocalErr = LocalBad

fn local_direct(seed: i32) -> LocalEntry:
    LocalEntry { name: "local-helper", rank: seed }

fn local_if(ok: bool) -> LocalEntry:
    if ok: LocalEntry { name: "local-if", rank: 10 } else: LocalEntry { name: "local-else", rank: 11 }

fn local_match(ok: bool) -> LocalEntry:
    match ok:
        true => LocalEntry { name: "local-match-yes", rank: 12 }
        false => LocalEntry { name: "local-match-no", rank: 13 }

fn local_option(ok: bool) -> Option[LocalEntry]:
    if ok: Some(LocalEntry { name: "local-some", rank: 14 }) else: None

fn local_result(ok: bool) -> Result[LocalEntry, LocalErr]:
    if ok: Ok(LocalEntry { name: "local-ok", rank: 15 }) else: Err(.LocalBad)

fn test_local_aggregate_flow:
    let direct_lit = LocalEntry { name: "local-direct", rank: 1 }
    assert(direct_lit.name == "local-direct")
    assert(direct_lit.rank == 1)

    let helper = local_direct(2)
    assert(helper.name == "local-helper")
    assert(helper.rank == 2)

    let if_val = local_if(true)
    assert(if_val.name == "local-if")
    assert(if_val.rank == 10)

    let match_val = local_match(false)
    assert(match_val.name == "local-match-no")
    assert(match_val.rank == 13)

    let some_val = match local_option(true):
        Some(v) => v
        None => LocalEntry { name: "missing", rank: -1 }
    assert(some_val.name == "local-some")
    assert(some_val.rank == 14)

    let none_val = match local_option(false):
        Some(v) => v
        None => LocalEntry { name: "none", rank: -2 }
    assert(none_val.rank == -2)

    let ok_val = match local_result(true):
        Ok(v) => v
        Err(_) => LocalEntry { name: "err", rank: -3 }
    assert(ok_val.name == "local-ok")
    assert(ok_val.rank == 15)

    let err_val = match local_result(false):
        Ok(v) => v
        Err(_) => LocalEntry { name: "err", rank: -4 }
    assert(err_val.rank == -4)

fn test_imported_aggregate_flow:
    let direct_lit = ImportedEntry { name: "imported-direct", rank: 3 }
    assert(direct_lit.name == "imported-direct")
    assert(direct_lit.rank == 3)

    let helper = imported_direct(4)
    assert(helper.name == "imported-helper")
    assert(helper.rank == 4)

    let if_val = imported_if(false)
    assert(if_val.name == "imported-else")
    assert(if_val.rank == 21)

    let match_val = imported_match(true)
    assert(match_val.name == "imported-match-yes")
    assert(match_val.rank == 30)

    let some_val = match imported_option(true):
        Some(v) => v
        None => ImportedEntry { name: "missing", rank: -5 }
    assert(some_val.name == "imported-some")
    assert(some_val.rank == 40)

    let none_val = match imported_option(false):
        Some(v) => v
        None => ImportedEntry { name: "none", rank: -6 }
    assert(none_val.rank == -6)

    let ok_val = match imported_result(true):
        Ok(v) => v
        Err(_) => ImportedEntry { name: "err", rank: -7 }
    assert(ok_val.name == "imported-ok")
    assert(ok_val.rank == 50)

    let err_val = match imported_result(false):
        Ok(v) => v
        Err(_) => ImportedEntry { name: "err", rank: -8 }
    assert(err_val.rank == -8)

fn main:
    test_local_aggregate_flow()
    test_imported_aggregate_flow()
    print("ok")
