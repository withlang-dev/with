//! expect-stdout: ok

use regression_matrix.types

type LocalBox {
    value: i32,
    label: str,
}

fn rank_of(entry: ImportedEntry) -> i32:
    entry.rank

fn local_from_if(ok: bool) -> LocalBox:
    if ok:
        let value = 12
        LocalBox { value, label: "yes" }
    else:
        let value = 13
        LocalBox { value, label: "no" }

fn imported_from_if(ok: bool) -> ImportedEntry:
    if ok:
        assert(true)
        imported_direct(21)
    else:
        let fallback = ImportedEntry { name: "if-fallback", rank: -2 }
        fallback

fn rank_from_if(ok: bool) -> i32:
    rank_of(
        if ok:
            assert(true)
            imported_direct(31)
        else:
            let fallback = ImportedEntry { name: "if-rank", rank: 32 }
            fallback
    )

fn after_if_value(ok: bool) -> i32:
    let _ = if ok:
        assert(true)
        1
    else:
        assert(true)
        2
    13

fn main:
    let yes = local_from_if(true)
    assert(yes.value == 12)
    assert(yes.label == "yes")

    let no = local_from_if(false)
    assert(no.value == 13)
    assert(no.label == "no")

    let imported_yes = imported_from_if(true)
    assert(imported_yes.name == "imported-helper")
    assert(imported_yes.rank == 21)

    let imported_no = imported_from_if(false)
    assert(imported_no.name == "if-fallback")
    assert(imported_no.rank == -2)

    assert(rank_from_if(true) == 31)
    assert(rank_from_if(false) == 32)

    assert(after_if_value(true) == 13)
    assert(after_if_value(false) == 13)

    print("ok")
