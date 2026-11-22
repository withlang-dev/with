//! expect-check-fail: undefined variable

// #1851 (§2.4): a `{ ... }` block holding one `let` is that binding's scope;
// the name is gone after the `}`. The parser returned the lone `let` in
// place of the block, so `t` joined main's scope and this compiled, printing
// "1" before the drop.

type Tok:
    n: i32

fn main:
    {
        let t = Tok { n: 1 }
    }
    print(f"{t.n}")
