//! expect-check-fail: if expressions do not establish one compatible owned result type

// #549: a value-position if with incompatible branch types must diagnose
// instead of silently poisoning to <error> (which let invalid code pass
// check). Statement-position ifs and distinct-over-same-base joins
// (BlockId vs raw i32) stay accepted.

fn main:
    let x: i32 = if true:
        "bad"
    else:
        1
