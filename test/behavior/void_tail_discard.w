//! expect-stdout: ok

fn discard_tail_remove:
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("x", 1)
    if m.contains("x"):
        m.remove("x")

fn main:
    discard_tail_remove()
    print("ok")
