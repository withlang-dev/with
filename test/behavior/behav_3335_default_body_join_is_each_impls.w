//! expect-stdout: 1 2 9 8
// #3335: a default method's body is checked for each impl, and a join in it
// whose demand is `Self` is decided for each impl's own signature. The
// first pass checks the trait's one body for every impl, and the decision
// was recorded with no signature: the second impl's met the first's and the
// compiler reported "conflicting contextual join decisions".
trait Pick:
    move fn pick(other: Self, first: bool) -> Self:
        if first: self else: other

type C { v: i32 }
impl Pick for i32
impl Pick for C

fn main:
    let one: i32 = 1
    let a = one.pick(2, true)
    let b = one.pick(2, false)
    let c = C { v: 9 }.pick(C { v: 8 }, true)
    let d = C { v: 9 }.pick(C { v: 8 }, false)
    print(f"{a} {b} {c.v} {d.v}")
