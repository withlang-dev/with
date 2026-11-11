//! expect-stdout: ok

// #3057: an Option bound out of a match on an element view is a view of
// the Option; `== None` beside it compares the value. MIR lowered the bare
// `None` as a null of the reference's type and LLVM refused the icmp of
// the aggregate with `i32 0`.
enum Spec:
    Scalar(i64)
    Slice(Option[i64], Option[i64], Option[i64])
    Dots
fn check(specs: &[Spec]):
    match specs[0]:
        .Slice(start, stop, step) =>
            assert(start == Some(2))
            assert(stop == Some(5))
            assert(step == None)
        _ => panic("slice")
fn main:
    let xs = [Spec.Slice(Some(2), Some(5), None), Spec.Dots]
    check(xs[0..])
    print("ok")
