use std.collections
use std.builtins.print
fn main:
    var sm: SlotMap[str] = SlotMap.new()
    let h = sm.insert("hello")
    print(*sm.get(h).unwrap())
    sm.remove(h)
    match sm.get(h):
        Some(v) => print("STALE:" ++ *v)
        None => print("stale-ok")
