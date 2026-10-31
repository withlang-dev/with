//! expect-stdout: 7 7

// D144/D179: a binding of a view of a trait object stays a view. A `dyn`
// is unsized, so `&dyn T` is the only form a binding can hold; copying
// "the pointee" has no meaning (the first stack battery trapped here:
// `let first = nested.source().unwrap()` in the Error-trait spec test).
trait Named:
    fn name(self: &Self) -> i32

type Tok { n: i32 }
impl Named for Tok:
    fn name(self: &Self) -> i32: self.n

type Holder { t: Tok }
impl Holder:
    fn get() -> Option[&dyn Named]: Some(&self.t)

fn main:
    let h = Holder { t: Tok { n: 7 } }
    let first = h.get().unwrap()
    let again = h.get()
    print(f"{first.name()} {again.unwrap().name()}")
