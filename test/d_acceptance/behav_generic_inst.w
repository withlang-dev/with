//! expect-stdout: 42
//! expect-stdout: hello
fn main:
    let vi: Vec[i32] = Vec.new()
    vi.push(42)
    print(int_to_string(vi[0]))
    let vs: Vec[str] = Vec.new()
    vs.push("hello")
    print(vs[0])
