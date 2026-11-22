//! expect-stdout: ok

// #2560: IndexPlace on a generic user type dispatches — the bounded impl is
// seen through the instance's arguments, and the subscript's `get`/`set`
// are the impl's methods specialized for the receiver (Sema records them,
// MIR lowers them: D65). Reads, writes and compound stores, two
// instantiations.

pub type Box3[T] { items: List[T] }
impl[T: Copy] IndexPlace[isize, T] for Box3[T]:
    fn get(self: &Self, index: isize) -> T: self.items[index]
    mut fn set(index: isize, value: T): self.items[index] = value

pub type Pairs[T] { items: List[T] }
impl[T] IndexPlace[i32, T] for Pairs[T]:
    fn get(self: &Self, index: i32) -> T: self.items[index].clone()
    mut fn set(index: i32, value: T): self.items[index] = value

fn ints():
    var b = Box3 { items: [1, 2, 3] }
    b[1] = 9
    assert(b[1] == 9 and b[0] == 1 and b[2] == 3)
    b[2] += 5
    assert(b[2] == 8)
    let sum = b[0] + b[1] + b[2]
    assert(sum == 18)

fn floats():
    var f = Box3 { items: [0.5, 1.5] }
    f[0] = f[0] + f[1]
    assert(f[0] == 2.0)

// IndexGet alone, yielding a view (the second half of #2560): `v[i]` is
// `&T` into the owner; there is no store.
pub type Views[T] { items: List[T] }
impl[T] IndexGet[isize, &T] for Views[T]:
    fn get(self: &Self, index: isize) -> &T from self: &self.items[index]

fn views():
    let v = Views { items: ["x", "y"] }
    assert(*v[0] == "x" and *v[1] == "y")
    let second = v[1]
    assert(second == "y")
    let n = Views { items: [10, 20, 30] }
    assert(*n[2] == 30 and *n[0] + *n[1] == 30)

fn is_z(s: &str) -> bool: *s == "z"

fn strings():
    var p = Pairs { items: ["a", "b"] }
    p[1] = "z"
    assert(p[1] == "z" and p[0] == "a")
    // The subscript as a call argument (lowered as a place).
    assert(is_z(p[1]) and not is_z(p[0]))
    let first = p[0]
    assert(first == "a")

fn main:
    ints()
    floats()
    strings()
    views()
    print("ok")
