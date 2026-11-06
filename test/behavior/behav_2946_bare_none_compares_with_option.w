//! expect-stdout: true false true
//! expect-stdout: true false
// #2946 (D97, §11.8): a bare `None` beside an `Option` in a comparison is that
// Option, as `.None` is: `None < Some(1)` compiles and `None` sorts first.
// Left as the bare generic, MIR refused it ("a generic declaration with no
// type arguments"). `None` beside `None` names no Option and is refused
// (err_2946_none_beside_none.w).
let some: Option[i32] = Some(1)
print(f"{None < Some(1)} {Some(1) < None} {Some(1) > None}")
print(f"{None != some} {some == None}")
