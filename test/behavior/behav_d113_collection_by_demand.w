//! expect-stdout: 10 4
//! expect-stdout: 6
//! expect-stdout: 2 true
//! expect-stdout: 1 2 3
//! expect-stdout: 7 7 7
//! expect-stdout: 5

// D113 (§4.3c rule 1): where a fixed array or a set is demanded, the
// literal builds it: an annotation, a parameter, a field, the repeat form.
use std.collections.HashSet
use std.collections.BTreeSet

type Row { cells: [i32; 3] }

fn sum3(xs: [i32; 3]): xs[0] + xs[1] + xs[2]

fn main:
    let t: [i32; 4] = [1, 2, 3, 4]
    print(f"{t[0] + t[1] + t[2] + t[3]} {t.len()}")
    let row = [1, 2, 3]
    print(sum3(row))
    let s: HashSet[str] = ["a", "b"]
    print(f"{s.len()} {s.contains("a")}")
    let o: BTreeSet[i32] = [3, 1, 2]
    var line = ""
    for n in o: line = if line.len() == 0: f"{n}" else: f"{line} {n}"
    print(line)
    let r = Row { cells: [7; 3] }
    print(f"{r.cells[0]} {r.cells[1]} {r.cells[2]}")
    let filled: [i32; 5] = [0; 5]
    print(filled.len())
