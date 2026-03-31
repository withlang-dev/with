//! expect-stdout: ok

use regression_matrix.types

type LocalPair {
    left: i32,
    right: i32,
}

fn score(entry: ImportedEntry) -> i32:
    entry.rank

fn local_from_match(ok: bool) -> LocalPair:
    match ok
        true =>
            let base = 4
            LocalPair { left: base, right: base + 1 }
        false =>
            let base = 9
            LocalPair { left: base, right: base + 1 }

fn imported_from_match(ok: bool) -> ImportedEntry:
    match imported_result(ok)
        Ok(v) =>
            assert(true)
            v
        Err(_) =>
            let fallback = ImportedEntry { name: "match-fallback", rank: -1 }
            fallback

fn score_from_match(ok: bool) -> i32:
    score(
        match imported_result(ok)
            Ok(v) =>
                assert(true)
                v
            Err(_) =>
                let fallback = ImportedEntry { name: "score-fallback", rank: 99 }
                fallback
    )

fn after_match_value(ok: bool) -> i32:
    let _ = match ok
        true =>
            assert(true)
            7
        false =>
            assert(true)
            8
    11

fn main:
    let pair_true = local_from_match(true)
    assert(pair_true.left == 4)
    assert(pair_true.right == 5)

    let pair_false = local_from_match(false)
    assert(pair_false.left == 9)
    assert(pair_false.right == 10)

    let imported_ok = imported_from_match(true)
    assert(imported_ok.name == "imported-ok")
    assert(imported_ok.rank == 50)

    let imported_err = imported_from_match(false)
    assert(imported_err.name == "match-fallback")
    assert(imported_err.rank == -1)

    assert(score_from_match(true) == 50)
    assert(score_from_match(false) == 99)

    assert(after_match_value(true) == 11)
    assert(after_match_value(false) == 11)

    print("ok")
