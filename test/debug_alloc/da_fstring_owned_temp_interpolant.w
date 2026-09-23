//! expect-debug-alloc: leak count=0

// #1390: formatting observes its interpolant, so an owned temporary in a hole
// (a call or `++` result, and the clone a spec'd or `:?` view formats) has no
// owner but its statement — it is a statement temp, dropped once the f-string
// is built. Every hole form below leaked one block per evaluation; the named
// owners (`x`, `move x`) are the controls that must not double-free.

fn holes(t: &str):
    print(f"{t.slice(0, 2)}")
    print(f"[{t.slice(0, 2):>5}]")
    print(f"{t.slice(0, 2):?}")
    print(f"{t ++ "!"}")
    print(f"{t.slice(0, 1)}-{t.slice(1, 3)}")
    print(f"{t.to_upper()}")
    print(f"[{t:>8}] {t:?}")
    let z = f"{t.slice(0, 2)}" ++ "!"
    print(z)
    let x = t.slice(0, 2)
    print(f"{x}{x}:{x:>3}")
    print(x)
    let y = t.slice(1, 3)
    print(f"{move y}")

fn main:
    let s = "abc" ++ "def"
    holes(&s)
    holes(&s)
