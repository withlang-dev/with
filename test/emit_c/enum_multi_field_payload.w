//! expect-stdout: pair 3 4
//! expect-stdout: triple 5 6 7
//! expect-stdout: named hello 9
//! expect-stdout: generic 1 2 x
//! expect-stdout: unit ok
//! expect-stdout: sum 34
//! expect-stdout: display Pair(3, 4) Triple(5, 6, 7) Named(hello, 9) Empty
//! expect-stdout: tuple payload 3 4

// #2017: an enum variant with several payload fields lays them out as a
// struct in the payload area (with-abi.md §2); the C backend refused every
// such variant ("C backend does not support enum variants with 2 payload
// fields"), so the compiler's own C could not be emitted. A one-field
// variant whose payload is a tuple read its payload field as the tuple's
// first element (`tuple payload 3 0`).

enum Shape { Pair(i32, i64) | Triple(i8, i32, i64) | Named(label: str, n: i32) | Empty }
enum Tagged[T] { Two(a: i32, b: i32, t: T) | Nothing }
enum Boxed { Tup((i32, i64)) | Bare }

fn make_pair(a: i32): Shape.Pair(a, a as i64 + 1)

fn weight(s: &Shape) -> i64:
    match s:
        .Pair(a, b) => a as i64 + b
        .Triple(a, b, c) => a as i64 + b as i64 + c
        .Named(_, n) => n as i64
        .Empty => 0

fn show(s: &Shape):
    match s:
        .Pair(a, b) => print(f"pair {a} {b}")
        .Triple(a, b, c) => print(f"triple {a} {b} {c}")
        .Named(label, n) => print(f"named {label} {n}")
        .Empty => print("unit ok")

fn main:
    let p = make_pair(3)
    show(&p)
    let t = Shape.Triple(5, 6, 7)
    show(&t)
    let n = Shape.Named("hel".clone() ++ "lo", 9)
    show(&n)
    let g: Tagged[str] = Tagged.Two(1, 2, "x".clone())
    match g:
        .Two(a, b, s) => print(f"generic {a} {b} {s}")
        .Nothing => print("generic none")
    let e = Shape.Empty
    show(&e)
    print(f"sum {weight(&p) + weight(&t) + weight(&n) + weight(&e)}")
    print(f"display {p} {t} {n} {e}")
    match Boxed.Tup((3, 4)):
        .Tup(pair) => print(f"tuple payload {pair.0} {pair.1}")
        .Bare => print("tuple payload none")
