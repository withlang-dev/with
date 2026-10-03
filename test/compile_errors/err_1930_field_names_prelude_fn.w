//! expect-error: bare 'panic' names both a field of the receiver `Policy` and the function `panic` (§9.5)

// §9.5 (#1930): the prelude's functions are module-level functions
// (std.builtins'), so a field of the same name makes the bare name a
// shadowing error.

type Policy {
    panic: bool,
}

impl Policy:
    fn check(ok: bool):
        if not ok and panic:
            print("refused")

fn main:
    let p = Policy { panic: true }
    p.check(false)
