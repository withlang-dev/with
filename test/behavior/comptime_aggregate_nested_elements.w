//! expect-stdout: inner
//! expect-stdout: 9

// #2026: the comptime evaluator laid a tuple's or an array's elements out
// after whatever evaluating them laid out first, so an element whose own
// evaluation built an aggregate shifted the run: `(rc, f((5, "inner")))`
// read back 5 where the call's result belonged. build.w's
// `(result.rc, ctx.fs().read_text(path))` returned the path.

comptime fn second(t: (i32, str)) -> str:
    let (_, s) = t
    s

comptime fn sum3(xs: [i32; 3]) -> i32:
    xs[0] + xs[1] + xs[2]

comptime fn tuple_probe() -> str:
    let (_, s) = (0, second((5, "inner")))
    s

comptime fn array_probe() -> i32:
    let xs = [1, sum3([2, 3, 4]), 5]
    xs[1]

const T: str = comptime tuple_probe()
const A: i32 = comptime array_probe()

fn main:
    print(T)
    print(A)
