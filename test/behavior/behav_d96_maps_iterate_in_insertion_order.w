//! expect-stdout: pear apple fig kiwi
//! expect-stdout: pear fig kiwi plum
//! expect-stdout: 3 1 4
// D96: a HashMap iterates in insertion order. An insert of a key already
// present replaces its value in place; a removal leaves the rest in order;
// growth keeps it.
use std.collections.HashMap

fn names(m: &HashMap[str, i32]) -> str:
    var out: Vec[str] = Vec.new()
    for (name, _) in m: out.push(name)
    out.join(" ")

fn main:
    var stock: HashMap[str, i32] = HashMap.new()
    for name in ["pear", "apple", "fig", "kiwi"]: stock.insert(name.to_lower(), name.len() as i32)
    stock.insert("apple".to_lower(), 9)
    print(names(stock))
    let _ = stock.remove("apple".to_lower())
    stock.insert("plum".to_lower(), 4)
    print(names(stock))
    var seen: HashMap[i64, bool] = HashMap.new()
    for n in [3, 1, 4, 1, 3]: seen.insert(n, true)
    for i in 0..200: seen.insert(1000 + i, true)
    for i in 0..200: let _ = seen.remove(1000 + i)
    var order: Vec[str] = Vec.new()
    for (n, _) in seen: order.push(f"{n}")
    print(order.join(" "))
