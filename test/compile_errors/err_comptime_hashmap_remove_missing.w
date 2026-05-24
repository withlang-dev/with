//! expect-check-fail: runtime value is not available at comptime

comptime fn remove_missing() -> i32:
    var m = HashMap[str, i32].new()
    m.insert("hello", 42)
    m.remove("nonexistent")

fn main:
    let bad: i32 = comptime remove_missing()
    assert(bad == 0)
