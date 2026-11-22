//! expect-stdout: 42 Local(7)
// §11.4: coherence permits an impl when EITHER the trait or the type is local:
// a local trait for a foreign type (Describe for i32) and a foreign/prelude
// trait for a local type (ToString for Local) are both allowed.
trait Describe:
    fn describe(self: &Self) -> i32
impl Describe for i32:
    fn describe(self: &Self) -> i32: *self + 1

type Local { n: i32 }
impl ToString for Local:
    fn to_string(self: &Local) -> str: f"Local({self.n})"

fn main:
    let a: i32 = 41
    let l = Local { n: 7 }
    print(f"{a.describe()} {l.to_string()}")
