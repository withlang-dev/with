//! expect-stdout: 7
//! expect-stdout: -1
use std.collections.HashMap

fn find(m: &HashMap[str, i32], k: &str) -> i32:
    let cur_opt = m.get(k)
    let cur: i32 = cur_opt ?? -1
    cur

fn main:
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("a", 7)
    print(find(&m, "a"))
    print(find(&m, "b"))
