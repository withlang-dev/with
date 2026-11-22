//! expect-stdout: alpha alpha 4
//! expect-stdout: beta beta
//! expect-stdout: gamma 0
//! expect-stdout: delta

// D179 (§3.8, amends D144): an unannotated binding of a view of `str`
// takes the `str` (an O(1) count copy, D111), so the root may be written
// after it: a list grown and its element replaced, a map grown past a
// reallocation, a list cleared. The binding keeps what it read.
use std.collections.HashMap

type Names { parts: List[str], by_id: HashMap[i32, str], lines: List[str] }

impl Names:
    mut fn first_then_grow() -> str:
        let s = self.parts[0]
        for i in 0..3: self.parts.push(f"more{i}")
        self.parts[0] = "replaced"
        f"{s} {s} {self.parts.len()}"
    mut fn lookup_then_grow() -> str:
        let name = self.by_id.get(1).unwrap()
        for i in 2..200: self.by_id.insert(i, f"n{i}")
        f"{name} {self.by_id.get(1).unwrap()}"
    mut fn line_then_clear() -> str:
        let line = self.lines[0]
        self.lines.clear()
        f"{line} {self.lines.len()}"

fn main:
    var n = Names { parts: ["alpha"], by_id: HashMap.new(), lines: ["gamma"] }
    n.by_id.insert(1, "beta")
    print(n.first_then_grow())
    print(n.lookup_then_grow())
    print(n.line_then_clear())
    let words: List[str] = ["delta"]
    let w = words[0]
    print(w)
