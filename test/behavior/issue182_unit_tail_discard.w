//! expect-stdout: after

type Frame {
    kind: i32,
    label: i32,
}

fn callee -> Unit:
    var v: Vec[Frame] = Vec.new()
    v.push(Frame { kind: 1, label: 2 })
    let _ = v.pop()

fn main:
    callee()
    print("after")
