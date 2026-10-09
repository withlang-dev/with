//! expect-stdout: 2
//! expect-build-stderr: duplicate element in a set literal
//! expect-build-stderr: behav_d113_set_duplicate_warns.w:10:38

// D113 (§4.3c rule 1): a duplicate constant in a literal demanded as a set
// warns; the set keeps one.
use std.collections.HashSet

fn main:
    let s: HashSet[str] = ["a", "b", "a"]
    print(s.len())
