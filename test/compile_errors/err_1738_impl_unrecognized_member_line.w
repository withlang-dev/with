//! expect-error: expected a member of this `impl`
//! expect-check-fail-not: undefined variable
// #1738: an indented impl body line the member loop does not accept is a
// parse error at that line. The loop used to end there silently and parse
// the rest of the body as top-level declarations, so `fn b` below became a
// free function and reported "undefined variable self".

type W { n: i32 }

impl W:
    fn a() -> i32: self.n
    let k = 3
    fn b() -> i32: self.n + 1

fn main:
    let w = W { n: 1 }
    print(w.a())
