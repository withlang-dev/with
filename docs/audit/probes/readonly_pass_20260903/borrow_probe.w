use std.collections
use std.builtins.print
fn main:
    var m: HashMap[str, str] = HashMap.new()
    m.insert("k", "v")
    let r = m.get("k").unwrap()
    m.clear()
    print(*r)
