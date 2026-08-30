//! expect-exit: 0

// #782 companion: the sanctioned PARTIAL uses of a partially moved
// binding stay legal — reading a live sibling field, and reinitializing
// the moved field to restore wholeness.

type Pair { left: str, right: str }

fn use_whole(p: &Pair) -> i64: p.left.len() + p.right.len()

fn main:
    var p = Pair { left: "ab" ++ "", right: "cdef" ++ "" }
    var taken = "" ++ ""
    taken = move p.left
    // Sibling read while p is partially moved: legal.
    if p.right.len() != 4:
        return 1
    // Reinitializing the moved field restores wholeness.
    p.left = "xy" ++ ""
    if use_whole(p) != 6:
        return 2
    if taken.len() != 2:
        return 3
    0
