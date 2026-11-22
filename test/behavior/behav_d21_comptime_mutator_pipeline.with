//! expect-stdout: ok

comptime fn named_chain() -> i32:
    var v: List[i32] = List[i32].new()
    v |> push(1) |> push(2) |> clear() |> push(42)
    v[0]

comptime fn rvalue_chain() -> List[i32]:
    List[i32].new() |> push(20) |> push(22)

const NAMED: i32 = comptime named_chain()
const BUILT: List[i32] = comptime rvalue_chain()

fn main:
    assert(NAMED == 42)
    assert(BUILT.len() == 2)
    assert(BUILT[0] + BUILT[1] == 42)
    print("ok")
