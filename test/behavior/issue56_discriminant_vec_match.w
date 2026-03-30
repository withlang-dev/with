//! expect-stdout: ok

enum TypeKind: i32:
    TY_ERR = 0
    TY_INT = 1
    TY_STR = 5

fn decode(kind: i32) -> str:
    match kind
        TypeKind.TY_STR => "str"
        TypeKind.TY_INT => "int"
        _ => "other"

fn decode_vec(kinds: Vec[i32], idx: i32) -> str:
    let kind = kinds.get(idx as i64)
    match kind
        TypeKind.TY_STR => "str"
        TypeKind.TY_INT => "int"
        _ => "other"

fn main:
    let kinds: Vec[i32] = Vec.new()
    kinds.push(TypeKind.TY_INT as i32)
    kinds.push(TypeKind.TY_STR as i32)
    assert(decode(TypeKind.TY_INT as i32) == "int")
    assert(decode(TypeKind.TY_STR as i32) == "str")
    assert(decode_vec(kinds, 0) == "int")
    assert(decode_vec(kinds, 1) == "str")
    print("ok")
