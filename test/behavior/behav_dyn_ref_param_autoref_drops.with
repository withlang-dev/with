//! expect-stdout: trace: peek1 peek2 peek3 end drop3 drop2 drop1

// §3.9, §3.8, §2.4: a value passed to a `&dyn T` parameter auto-references
// into it, as into a `&T` parameter, and its owner drops it once at scope
// end (reverse declaration order). On base `peek(a)` moved `a` into the
// call and nothing dropped it (`drop1` missing; a str-holding implementor
// leaked), and so did `peek(c)` on a `var`; the explicit `&b` was fine.
// One trace line (expect-stdout is substring-matched, #1855).

global var TRACE = ""

fn note(s: &str): TRACE = TRACE ++ " " ++ s

trait Shape:
    fn area(self: &Self) -> i32

type Circle { radius: i32 }

impl Shape for Circle:
    fn area(self: &Self) -> i32: self.radius

impl Drop for Circle:
    move fn drop(): note(f"drop{self.radius}")

fn peek(s: &dyn Shape): note(f"peek{s.area()}")

fn scenario:
    let a = Circle { radius: 1 }
    peek(a)
    let b = Circle { radius: 2 }
    peek(&b)
    var c = Circle { radius: 3 }
    peek(c)
    note("end")

fn main:
    scenario()
    print("trace:" ++ TRACE)
