//! expect-stdout: 2 1
// #2520 shape 2: two traits can each give one type a method of the same
// name; each impl is its own function and a bound names which trait
// dispatches. Before trait identity, both impls minted the fn symbol
// `f64.one`-style (`Type.method`, no trait in it) and MIR reported
// "body index map mismatch for fn symbol N".
trait Two:
    fn one() -> Self

impl Two for i32:
    fn one(): 2

fn via_two[T: Two]() -> T: T.one()
fn via_one[T: One]() -> T: T.one()

fn main:
    let a: i32 = via_two()
    let b: i32 = via_one()
    print(f"{a} {b}")
