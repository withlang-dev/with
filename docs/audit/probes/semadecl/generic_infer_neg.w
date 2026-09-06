// SemaDecl probe NEGATIVE: generic call with inferable param passes
fn semadecl_ident[T](x: T) -> T:
    x

fn main:
    assert(semadecl_ident(41) == 41)
    print("infer ok")
