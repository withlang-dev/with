//! expect-error: an aggregate's elements do not convert

// D27 / #1354: the named-let spelling of the same rule — the annotation and
// the value share one check (check_binding_annotation).

fn pair -> (i32, i32): (3, 4)

fn main:
    let t: (i64, i64) = pair()
    print(f"{t.0} {t.1}")
