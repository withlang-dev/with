//! expect-check-fail: undefined variable

// #1941 class: an impl method written without a return type returns what
// its trait declares, a fact of the declarations. Checked with `main`
// before the impl (sema-order-check), `print[P]` read `P.to_str` as Unit
// and reported a wrong argument type inside std.builtins as well.
type P { x: i32 }

impl Display for P:
    fn to_str(): f"P({self.x})"

fn main:
    print(P { x: 7 })
    let y = missing_name
