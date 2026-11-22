//! expect-stdout: hi!
// §5.2 (#626): a `&T` field coercing a BORROWED parameter (which outlives the
// call) is safe — the origin is not a dying local. (Post-D5 a plain `str`
// param consumes, so the original `src: str` spelling returned a view of a
// dying param — see #718 for the missing rejection.)
type View ephemeral { s: &str }
fn f(src: &str) -> View:
    View { s: src }
fn main:
    let s = "hi"
    let v = f(s)
    print(v.s ++ "!")
