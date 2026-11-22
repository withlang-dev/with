//! expect-stdout: 3
//! expect-stdout: 13
//! expect-stdout: 4
//! expect-stdout: 4
//! expect-stdout: 4
//! expect-stdout: 1
//! expect-stdout: 2
//! expect-stdout: 1
//! expect-stdout: sq
//! expect-stdout: drop t3
//! expect-stdout: 4
//! expect-stdout: end

// D223 (§9.3a): `Type.method` names the method as a function value. Its
// first parameter is the receiver, in the mode the method declares: `&T`
// for `fn`, `mut T` for `mut fn`, `T` for `move fn`; a method with no
// receiver has none. A method of a generic type is named through the
// instance (`Box[i32].count`). `Type.name` is a variant before it is a
// method, as at a call.
type Tag { name: str }
impl Drop for Tag:
    move fn drop(): print(f"drop {self.name}")

type Bag { n: i32, tag: Tag }
impl Bag:
    fn peek() -> i32: self.n
    fn plus(k: i32) -> i32: self.n + k
    mut fn bump() -> i32:
        self.n += 1
        self.n
    move fn into_n() -> i32: self.n

fn Bag.make(v: i32) -> Bag: Bag { n: v, tag: Tag { name: f"t{v}" } }

type Box[T] { v: T }
impl[T] Box[T]:
    fn count() -> i32: 1

enum Shape:
    Circle(r: i32)
    Square
impl Shape:
    fn area() -> i32: 1

fn observe(f: fn(&Bag) -> i32, b: &Bag) -> i32: f(b)
fn change(f: fn(mut Bag) -> i32, mut b: Bag) -> i32: f(b)

fn main:
    let mk = Bag.make
    var b = mk(3)
    let peek = Bag.peek
    print(peek(b))
    let plus = Bag.plus
    print(plus(b, 10))
    print(change(Bag.bump, b))
    print(b.n)
    print(observe(Bag.peek, b))
    let boxed: Box[i32] = Box { v: 7 }
    let count = Box[i32].count
    print(count(boxed))
    let rest = List[i32].rest
    print(rest([1, 2, 3]).len())
    let area = Shape.area
    let s = Shape.Square
    print(area(s))
    match s:
        .Square => print("sq")
        .Circle(r) => print(r)
    let eat = Bag.into_n
    print(eat(b))
    print("end")
