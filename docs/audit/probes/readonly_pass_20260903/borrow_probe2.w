use std.collections
use std.builtins.print
fn lookup(m: &HashMap[str, str], k: &str) -> Option[&str]:
    let r = m.get(k)?
    Some(r)
fn main:
    var m: HashMap[str, str] = HashMap.new()
    m.insert("k", "v")
    print(*m.get("k").unwrap())
    print(*lookup(&m, "k").unwrap())
    m.clear()
    print("cleared")
