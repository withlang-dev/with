// T10: ?? grouping vs +. Spec §9.9 L10 lists `??` with `+`/`-` LEFT-assoc,
// so Ok(5) ?? 10 + 1 should be (Ok(5) ?? 10) + 1 == 6 under the spec.
// Parser.w:3436 makes OP_DEFAULT right-assoc: Ok(5) ?? (10 + 1) == 5.
enum MyResult { Ok(i32) | Err(str) }

fn divide(a: i32, b: i32) -> MyResult:
    if b == 0:
        .Err("div by zero")
    else:
        .Ok(a / b)

fn main:
    assert((divide(10, 2) ?? 10 + 1) == 5)
