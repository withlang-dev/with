//! expect-stdout: 3 5 7 11 13 1

// #1346 (§29.13): trait and impl bodies take the same three forms as `fn`.
// Form 1: one member on the header line; its parameter list may continue
// across lines inside the parentheses (a newline inside balanced delimiters
// does not end the inline body). Form 2: the indented members below a ':'
// that ends the line. Form 3: braces, members separated by newlines or
// semicolons. A bodyless impl (§2.3) ends at its newline.

trait One: fn one(self: &Self) -> i32

trait Wide: fn wide(self: &Self,
    k: i32) -> i32

trait Two:
    fn a(self: &Self) -> i32
    fn b(self: &Self) -> i32

trait Braced { fn c(self: &Self) -> i32; fn d(self: &Self) -> i32 }

trait Marker {}

type X { v: i32 }

impl One for X: fn one(): self.v + 2

impl Wide for X: fn wide(
    k: i32): self.v + k

impl Two for X:
    fn a(): 7
    fn b(): 11

impl Braced for X { fn c(): 13; fn d(): 1 }

impl Marker for X

fn main:
    let x = X { v: 1 }
    print(f"{x.one()} {x.wide(4)} {x.a()} {x.b()} {x.c()} {x.d()}")
