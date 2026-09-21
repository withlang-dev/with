//! expect-check-fail: cannot move out of global `g`

// #1242: a returned global is not routed through the consume arm; the
// return walker rejects it the same way (tail and explicit `return`).

var g: Vec[str] = Vec.new()

fn tail() -> Vec[str]: g

fn main:
    g.push("a")
    print(f"{tail().len()}")
