//! expect-stdout: Red
//! expect-stdout: Green 2
//! expect-stdout: ok

// A variant constructor is an rvalue, not a field of the type: a `&Color`
// parameter auto-references it through a materialized temporary the same
// way it does a struct literal. MIR lowering once routed `Color.Red` to the
// field-place path and failed to lower the call.

enum Color { Red | Green(i32) }

fn show(c: &Color):
    match *c:
        Red => print("Red")
        Green(n) => print(f"Green {n}")

fn main:
    show(Color.Red)
    show(Color.Green(2))
    print("ok")
