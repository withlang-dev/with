//! expect-error: drop '=' in struct type declarations

// §5.1: `type Name ephemeral { … }` is the one spelling; the `=` is refused
// for an ephemeral struct exactly as for a plain one (err_legacy_struct_equals).
type View = ephemeral { s: &str }

fn main:
    let v = View { s: "hi" }
    print(v.s)
