//! expect-stdout: ok

// #695 follow-up: the branch-merge of the partial-move set must DEDUP, not
// concatenate. Concatenation made the moved-field arrays grow ~2^N across N
// nested/sequential branches (a field re-added on every merge), which the
// cloning at each branch turned into catastrophic compile memory (the #691
// flip compiled in ~100 GB before dedup, ~1 GB after). This function moves a
// distinct Drop-bearing field out on each of four nested branches, so the
// merge unions overlapping partial-move sets — the exact path the dedup guards.
//
// It must also stay CORRECT: exactly one field is moved on each path, so the
// three un-moved fields plus `tag` must still be live and drop normally at the
// end (verified value-wise here, and drop-exactly-once under --debug-alloc).
// Over-dedup that dropped a real move would double-drop the moved field;
// under-dedup that wrongly poisoned a sibling would leak it.

type D { id: i32 }
impl Drop for D:
    fn drop(move self: Self): ()

// Bag has no Drop impl but Drop-bearing fields (transitive Drop): partial moves
// out of it are the explicit `move` vacate (D32 §2.2).
type Bag { a: D, b: D, c: D, d: D, tag: i32 }

fn churn(k: i32) -> i32:
    var bag = Bag { a: D { id: 1 }, b: D { id: 2 }, c: D { id: 3 }, d: D { id: 4 }, tag: 10 }
    var acc = 0
    if k > 0:
        if k > 1:
            let x = move bag.a
            acc = acc + x.id
        else:
            let y = move bag.b
            acc = acc + y.id
    else:
        if k < -1:
            let z = move bag.c
            acc = acc + z.id
        else:
            let w = move bag.d
            acc = acc + w.id
    acc + bag.tag

fn main:
    assert(churn(2) == 11)   // moved a (id 1) + tag 10
    assert(churn(1) == 12)   // moved b (id 2) + tag 10
    assert(churn(-2) == 13)  // moved c (id 3) + tag 10
    assert(churn(0) == 14)   // moved d (id 4) + tag 10
    print("ok")
