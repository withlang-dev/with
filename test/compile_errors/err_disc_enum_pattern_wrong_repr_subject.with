//! expect-error: qualified enum pattern requires an enum subject
enum TypeKind: i32:
    TY_ERR = 0
    TY_INT = 1
    TY_STR = 5

fn main:
    let kind: i64 = 5
    let _ = match kind:
        TypeKind.TY_STR => "str"
        _ => "other"
