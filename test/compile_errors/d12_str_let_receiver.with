//! expect-error: cannot mutate immutable binding `s`

// D12/#678: every mut-fn write on a str owner replaces the whole slice —
// on a `let` binding that is exactly the forbidden rebinding.

extend str:
    mut fn behead(): self = self.slice(1, self.len())

fn main:
    let s = "hello"
    s.behead()
