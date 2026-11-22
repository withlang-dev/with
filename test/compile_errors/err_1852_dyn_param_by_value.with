//! expect-check-fail: a parameter cannot take `dyn Named` by value: a trait object is unsized (§11.3)

// #1852 (§11.3, §3.9): the spec defines a trait object borrowed (`&dyn T`)
// and owned (`Box[dyn T]`); `dyn T` itself is unsized. A by-value `dyn T`
// parameter compiled, took `t`, and neither side ran `Tok`'s Drop. It is
// refused at the parameter, with both spellings as help.

trait Named:
    fn name(self: &Self) -> i32

type Tok:
    n: i32

impl Named for Tok:
    fn name(self: &Self) -> i32: self.n

fn describe(s: dyn Named) -> i32: s.name()

fn main:
    let t = Tok { n: 1 }
    print(f"{describe(t)}")
