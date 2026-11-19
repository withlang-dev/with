//! expect-check-fail: use of moved value: the list pattern at line 12 took `xs` apart
//! expect-check-fail: = help: `xs` is a by-value parameter, an owned subject, so the pattern takes its elements; declare it `xs: &List[Tag]` and the pattern views it (§9.7)

// #3461: a list of resources taken apart by a list pattern is gone; the
// error names the pattern and the spelling that keeps the list.
type Tag { name: str }
impl Drop for Tag:
    move fn drop(): print(f"drop {self.name}")

fn f(xs: List[Tag]) -> i32:
    match xs:
        [h, ..rest] => print(h.name)
        [] => print("none")
    xs.len() as i32

fn main: print(f([Tag { name: "a" }]))
