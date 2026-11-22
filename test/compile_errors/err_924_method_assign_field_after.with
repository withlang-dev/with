//! expect-check-fail: only method calls follow `.=`: write the assignment out, `x = x.f(args)` and the rest

// #924 (§4.2.5): only method calls follow `.=`. A field after the call is
// refused.
type Pair { a: i32, b: i32 }

impl Pair:
    fn swapped() -> Pair: Pair { a: self.b, b: self.a }

fn main:
    var n = 3
    var p = Pair { a: 1, b: 2 }
    p .= swapped().a
    print(n)
