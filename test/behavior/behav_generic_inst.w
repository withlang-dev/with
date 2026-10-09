//! expect-stdout: 42
//! expect-stdout: hello
use std.builtins.int_to_string
fn main:
    let vi: List[i32] = List.new()
    vi.push(42)
    print(int_to_string(vi[0]))
    let vs: List[str] = List.new()
    vs.push("hello")
    print(vs[0])
