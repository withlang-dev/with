//! expect-stdout: ok

// #727 / D7: inside a trait IMPL, keyword receiver forms synthesise —
// disambiguation is trait-contract-driven, so location plus the trait's
// own declaration decide instance vs associated. Three pins:
//   1. a read instance contract implemented as plain `fn` (self usable);
//   2. an associated contract implemented as plain no-receiver `fn`;
//   3. the decisive case — an instance contract whose body never touches
//      `self` still dispatches as an instance method (proves the lookup
//      consults the trait, not the body).
// Trait DECLARATIONS keep explicit `self: &Self` on read contracts by
// D7's carve-out (associated contracts must stay spellable).

use std.builtins.print

trait Named:
    fn name(self: &Self) -> str

trait Makeable:
    fn make() -> Self

type P { n: str }
impl Named for P:
    fn name() -> str: self.n.clone()

type Q { v: i32 }
impl Makeable for Q:
    fn make() -> Q: Q { v: 7 }

type R { n: str }
impl Named for R:
    fn name() -> str: "fixed" ++ ""

fn main:
    let p = P { n: "p-named" ++ "" }
    assert(p.name() == "p-named")
    let q = Q.make()
    assert(q.v == 7)
    let r = R { n: "ignored" ++ "" }
    assert(r.name() == "fixed")
    print("ok")
