//! expect-stdout: 3 3 3 3 6 6
// #2774 (§4.4a, §4.2.6): a discriminant enum is its integer value, and an
// enum argument auto-referenced into an `&i64`, `&isize` or `&i32`
// parameter is viewed through a temporary at the pointee's width, as a
// narrower integer is (#2336). It went by value and the callee read eight
// bytes from the enum's four: `next` (7) landed in the upper half and
// `K.A` read as 30064771075. An operator method's parameter is the same
// demand: `v * h.k` printed 60129542150.
enum K: i32:
    A = 3

enum B: u8:
    A = 3

type Holder:
    k: K
    next: i32

type Bytes:
    b: B
    n1: u8
    n2: u8
    n3: u8

type V:
    n: i64

impl V:
    fn mul(k: &i64) -> i64: self.n * k

fn wide(k: &i64) -> i64: k
fn word(k: &isize) -> isize: k
fn narrow(k: &i32) -> i32: k

fn main:
    let h = Holder { k: K.A, next: 7 }
    let g = Bytes { b: B.A, n1: 7, n2: 7, n3: 7 }
    let v = V { n: 2 }
    print(f"{wide(h.k)} {word(h.k)} {narrow(g.b)} {wide(g.b)} {v * h.k} {v.mul(h.k)}")
