//! expect-stdout: abi-matrix-ok

type Small { a: i32, b: i32 }
type Big { a: i64, b: i64, c: i64, d: i64 }
type Counter { value: i64, pad1: i64, pad2: i64 }
type GBox[T] { value: T }

fn scalar(x: i32) -> i32: x + 1
fn small(v: Small) -> Small: Small { a: v.a + 1, b: v.b + 2 }
fn big(v: Big) -> Big: Big { a: v.a + 1, b: v.b + 2, c: v.c + 3, d: v.d + 4 }
fn unit(x: &Small): assert(x.a > 0)
fn unit_value -> Unit: return
fn accepts_unit(_value: Unit): return
fn identity[T](value: T) -> T: value

impl Counter:
    fn read(): self.value
    mut fn add(delta: i64): self.value = self.value + delta
    move fn take(): self.value

impl[T] GBox[T]:
    fn get(): self.value

fn apply_scalar(f: fn(i32) -> i32, value: i32) -> i32: f(value)
fn apply_big(f: fn(Big) -> Big, value: Big) -> Big: f(value)
fn apply_raw(f: *const fn(Big) -> Big, value: Big) -> Big: f(value)

trait Transform:
    fn transform(self: &Self, value: Big) -> Big

type Shift { amount: i64 }
impl Transform for Shift:
    fn transform(value: Big) -> Big:
        Big { a: value.a + self.amount, b: value.b, c: value.c, d: value.d }

fn apply_dyn(transform: &dyn Transform, value: Big) -> Big: transform.transform(value)

extern "C" fn abs(x: i32) -> i32

fn diverge() -> Never: panic("unreached")
fn choose(flag: bool) -> i32:
    if flag:
        return 17
    diverge()

fn default_i32 -> i32:
    unit(&Small { a: 1, b: 2 })

fn main:
    assert(scalar(4) == 5)
    scalar(8)

    let s = small(Small { a: 1, b: 2 })
    assert(s.a == 2 and s.b == 4)
    unit(&s)
    accepts_unit(unit_value())

    let b = big(Big { a: 1, b: 2, c: 3, d: 4 })
    assert(b.a == 2 and b.d == 8)
    big(Big { a: 3, b: 4, c: 5, d: 6 })
    let gb = identity(Big { a: 10, b: 20, c: 30, d: 40 })
    assert(gb.c == 30)

    var counter = Counter { value: 5, pad1: 0, pad2: 0 }
    assert(counter.read() == 5)
    counter.add(7)
    assert(counter.read() == 12)
    assert(counter.take() == 12)

    let generic_box = GBox { value: 42 }
    assert(generic_box.get() == 42)

    assert(apply_scalar(scalar, 9) == 10)
    let offset = 3
    assert(apply_scalar(x => x + offset, 4) == 7)
    let cb = apply_big(big, Big { a: 4, b: 5, c: 6, d: 7 })
    assert(cb.d == 11)
    let rb = apply_raw(&big, Big { a: 8, b: 9, c: 10, d: 11 })
    assert(rb.a == 9 and rb.d == 15)

    let shift = Shift { amount: 10 }
    let db = apply_dyn(&shift, Big { a: 1, b: 2, c: 3, d: 4 })
    assert(db.a == 11 and db.d == 4)

    assert(abs(-19) == 19)

    assert(choose(true) == 17)
    assert(default_i32() == 0)
    print("abi-matrix-ok")
