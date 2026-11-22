//! expect-stdout: trace: circle5 rect7 other end drop7 drop5

// #1860 (Eric, 2026-09-28, option (a)): a typed binding over a `&dyn T`
// subject is a view of the object, so the object is dropped once, by its
// owner, after the match observed it, in reverse declaration order (§2.4).
// On base the binding was a byte copy of the object (a second owner). A
// non-sealed trait's match has a `_` arm. One trace line (expect-stdout
// is substring-matched, #1855).

global var TRACE = ""

fn note(s: &str): TRACE = TRACE ++ " " ++ s

trait Shape:
    fn area(self: &Self) -> i32

type Circle { radius: i32 }
type Rect { width: i32, height: i32 }
type Blob { n: i32 }

impl Shape for Circle:
    fn area(self: &Self) -> i32: self.radius
impl Shape for Rect:
    fn area(self: &Self) -> i32: self.width * self.height
impl Shape for Blob:
    fn area(self: &Self) -> i32: self.n

impl Drop for Circle:
    move fn drop(): note(f"drop{self.radius}")
impl Drop for Rect:
    move fn drop(): note(f"drop{self.area()}")

fn describe(s: &dyn Shape):
    match s:
        c: Circle => note(f"circle{c.radius}")
        r: Rect => note(f"rect{r.width * r.height}")
        _ => note("other")

fn scenario:
    let c = Circle { radius: 5 }
    let r = Rect { width: 7, height: 1 }
    describe(c)
    describe(r)
    describe(Blob { n: 1 })
    note("end")

fn main:
    scenario()
    print("trace:" ++ TRACE)
