//! expect-stdout: 8 6
// #3343: the body an impl inherits from its trait is lowered with the
// module, like any function of the impl. Codegen built it itself, after
// every check on MIR had run, so:
//  - a closure the body creates reached no module ("BUG: anonymous
//    expression lacks retained MIR");
//  - a function only that body names was known to nothing before codegen
//    (#3351: left out of a program walked from its roots, an undefined
//    symbol at link).
fn only_the_default_calls_this(n: i32) -> i32: n * 2

trait Scaler:
    fn factor(self: &Self) -> i32
    fn scaled(self: &Self, n: i32) -> i32:
        let f = self.factor()
        let apply = (x: i32) => x * f
        apply(n)
    fn doubled(self: &Self) -> i32: only_the_default_calls_this(self.factor() + 1)

type Twice { k: i32 }

impl Scaler for Twice:
    fn factor(self: &Self) -> i32: self.k

fn main:
    let t = Twice { k: 2 }
    print(f"{t.scaled(4)} {t.doubled()}")
