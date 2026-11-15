//! expect-stdout: 1 9 1 7
// #3335: `Self.make(x)` in a method body calls the type's static method.
// Sema read `Self` as the type and resolved the call with no receiver; MIR
// asked again whether the receiver named a type, in a table where `Self`
// is bound only while its body is checked, and passed a receiver the callee
// does not take (invalid LLVM, or "MIR lowering failed").
trait Make:
    fn make(x: &str) -> Option[Self]
    fn one() -> Self
    fn must(x: &str) -> Self:
        let got = Self.make(x)
        got.unwrap()
    fn first() -> Self:
        let got = Self.one()
        got

type C { v: i32 }

impl Make for i32:
    fn make(x: &str) -> Option[i32]: if x == "1": Some(1) else: None
    fn one() -> i32: 1

impl Make for C:
    fn make(x: &str) -> Option[C]: Some(C { v: 9 })
    fn one() -> C: C { v: 7 }

fn main:
    let a: i32 = i32.must("1")
    let b = C.must("x")
    let c: i32 = i32.first()
    let d = C.first()
    print(f"{a} {b.v} {c} {d.v}")
