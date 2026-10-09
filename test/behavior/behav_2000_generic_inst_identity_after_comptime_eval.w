//! expect-stdout: 3
//! expect-stdout: none
//! expect-stdout: 8

// #2000: a comptime evaluation (here the `[0; 4]` count) hands Sema back
// with its generic-instance memo emptied, and preregister_mir_types read
// the memo's absence as "no Option[V] for HashMap[K, V] yet": it created a
// second Option[i32]. A generic body re-checked before lowering then joined
// its `if` at the duplicate while the first check had joined at the
// original: "internal error: conflicting contextual join decisions for one
// expression" (first seen in std/collections/sorted_list.w index_of).

use std.collections.HashMap

type Finder[T]:
    value: T

impl Finder[T]:
    fn find(at: i32) -> Option[i32]:
        if at < 0: None else: Some(at)

fn main:
    let finder: Finder[i32] = Finder { value: 1 }
    match finder.find(3):
        Some(at) => print(f"{at}")
        None => print("none")
    match finder.find(-1):
        Some(at) => print(f"{at}")
        None => print("none")
    let counts = [0; 4]
    var map = HashMap[i32, i32].new()
    map.insert(1, 8)
    print(f"{map.get(1).unwrap() + counts[0]}")
