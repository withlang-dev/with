//! expect-stdout: [f!]
//! expect-stdout: [one]
//! expect-stdout: [seven]
//! expect-stdout: 2

// D111: passing a str copies it, so a str pushed or inserted and then
// returned is still the caller's. The function body's tail `out` moved the
// local after its scope had ended it (`StorageDead(_4); _0 = move _4`), so
// the last-use pass took the earlier copy as the local's last use and
// blanked it: every one of these returned "".
use std.collections.HashMap

fn pushed(text: &str) -> str:
    var xs: List[str] = List.new()
    let out = text ++ "!"
    xs.push(out)
    out

type Holder:
    texts: HashMap[i32, str]

impl Holder:
    mut fn remember(id: i32, text: &str) -> str:
        var out: str = text
        if id == 7:
            out = "seven"
        self.texts.insert(id, out)
        out

fn main:
    print("[" ++ pushed("f") ++ "]")
    var h = Holder { texts: HashMap.new() }
    print("[" ++ h.remember(1, "one") ++ "]")
    print("[" ++ h.remember(7, "x") ++ "]")
    print(h.texts.len())
