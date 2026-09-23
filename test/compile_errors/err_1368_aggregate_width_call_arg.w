//! expect-error: wrong argument type in call to 'f'

// #1368: a tuple whose elements differ in width from the parameter's is a
// Sema error at the call; it used to reach codegen ("wrong argument type
// actual=struct{i32,i32} expected=struct{i64,i64}").
fn f(t: (i64, i64)) -> i64: t.0 + t.1
fn pair -> (i32, i32): (3, 4)
fn main:
    print(f"{f(pair())}")
