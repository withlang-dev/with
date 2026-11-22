//! expect-stdout: 0 0 4 15

// #1967: name resolution tiers. A visible module's `pub type T` is a
// candidate for the name `T`; a generic function's type parameter `T` is a
// scoped binding and is lexically closer, so inside `d[T]` (and its
// instantiation) `T.default()` is the parameter's — i32's 0, str's "" —
// never the imported struct's ("unknown method 'default' for type 'T'").
// The module's struct stays reachable by the short name outside the generic.

use issue1967.shadow_t

fn d[T: Default](w: T) -> T: T.default()

fn pick[T](x: T) -> T: x

fn main:
    let s = d("ab")
    let t: T = make_t(7)
    let u = make_t(8)
    print(f"{d(5)} {s.len()} {pick(3) + 1} {t.v + u.v}")
