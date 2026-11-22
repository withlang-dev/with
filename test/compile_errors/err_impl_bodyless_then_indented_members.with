//! expect-check-fail: `impl Foo for X` has no ':' or '{', so it is a bodyless impl that ends at its newline

// #1346 (§2.3, §29.13): `impl Foo for X` with no introducer is a bodyless
// marker impl, complete at its newline. The indented `fn` below it is not its
// member; the fix-it is the missing ':'.

type X { v: i32 }

trait Foo:
    fn a(self: &Self) -> i32

impl Foo for X
    fn a(self: &Self) -> i32: 5

fn main:
    let x = X { v: 0 }
    print(f"{x.a()}")
