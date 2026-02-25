// Phase 2 gap: auto-generated enum as_*_ref/as_*_mut accessors not codegen-complete
type Shape = Circle(i32) | Point

fn main() -> i32 =
    let c = Circle(5)
    let r = c.as_Circle_ref()
    if r.is_none() then return 1
    if r.unwrap() == 5 then 0 else 1
