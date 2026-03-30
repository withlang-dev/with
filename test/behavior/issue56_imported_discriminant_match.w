//! expect-stdout: ok
use issue56.kinds

fn decode(kind: i32) -> str:
    match kind
        TypeKind.TY_STR => "str"
        TypeKind.TY_INT => "int"
        _ => "other"

fn main:
    let kinds: Vec[i32] = Vec.new()
    kinds.push(TypeKind.TY_INT as i32)
    kinds.push(TypeKind.TY_STR as i32)
    assert(decode(kinds.get(0)) == "int")
    assert(decode(kinds.get(1)) == "str")
    print("ok")
