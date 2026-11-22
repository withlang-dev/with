//! expect-error: bind the field under another name, e.g. `repr: r`; the field is `repr` or `self.repr`

// §9.5 (#1930), §29.8, #1272: a destructuring shorthand binds the field's own
// name, a local that would shadow the receiver field; the fix-it binds it
// under another (`let { repr: r, other: _ } = self`).

var count: i32 = 0
type R { repr: i32, other: i32 }
impl Drop for R:
    move fn drop(): count = count + 1

impl R:
    move fn take() -> i32:
        let { repr, other: _ } = self
        repr

fn main:
    let r = R { repr: 7, other: 0 }
    print(f"{r.take()}")
