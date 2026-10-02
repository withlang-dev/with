//! expect-stdout: 3
// §3.8/§21.1: a `mut fn` on an ephemeral receiver returns a child that views
// what self views (the pointee), never self's own storage — self is a borrowed
// place, not a value the call received. Mutating self afterwards while the
// child is live is fine (the MirBuilder.begin_gen_loop_closure/finish_gen_loop
// shape, the #1737 stage2 regression).
use std.builtins.print_i32
type Builder ephemeral { src: &i32, n: i32 }
fn Builder.mk(src: &i32) -> Builder: Builder { src, n: 0 }
impl Builder:
    mut fn child() -> Builder:
        var c = Builder.mk(self.src)
        c.n = 1
        c
    mut fn finish(c: Builder): self.n = self.n + c.n + *c.src
fn main:
    let x = 1
    var b = Builder { src: &x, n: 0 }
    var c = b.child()
    c.n = 2
    b.finish(move c)
    print_i32(b.n)
