//! expect-stdout: point: other|x0 y=7|xneg y=4|x1-5 y9|other|x7 anon|y0 x=9|diag 6|
//! expect-stdout: flag: on 1|off3|off-other|
//! expect-stdout: char: a 1|b|ch-other|
//! expect-stdout: str: bob 1|al two|nm-other|
//! expect-stdout: nested: a1 b=2|t2 z=8|some5|none a=4|ou-other|
//! expect-stdout: wrap: x0 z|y9 x=0 tag=113|digit tag|w-other|
//! expect-stdout: guard: x0 big 9|x0 small 2|diag12|rest|y3|y4 wild|rest|
//! expect-stdout: generic: pa1 5|pb2 3|p-other|
//! expect-stdout: at: at 11|no-at|
//! expect-stdout: if-let: iflet 6|iflet-miss|
//! expect-stdout: let-else: 7|-1|
//! expect-stdout: stmt: stmt 1|
//! expect-stdout: for: 55|5|
//! expect-stdout: exhaustive: ascii|high|2|2|

// #1388 (§9.7): a literal (refutable) sub-pattern on a struct field is
// tested. `Point { x: 0, y }` used to match any `x` in match, if let and
// let-else: the named-field struct pattern fell into MirLower's
// accept-everything default. Every arm below is reached by exactly the
// values it names; each line is one function's results in call order.

type Point { x: i32, y: i32 }
type Flag { on: bool, n: i32 }
type Ch { c: u8, n: i32 }
type Named { name: str, n: i32 }
type Inner { a: i32, b: i32 }
type Outer { inner: Inner, t: (i32, i32), o: Option[i32] }
type Pair[T] { a: T, b: T }
type Wrap { p: Point, tag: u8 }

fn pt(p: Point) -> str:
    match p:
        Point { x: 0, y } => f"x0 y={y}"
        Point { x: -1, y } => f"xneg y={y}"
        Point { x: 1..=5, y: 9 } => "x1-5 y9"
        { x: 7, .. } => "x7 anon"
        Point { x, y: 0 } => f"y0 x={x}"
        Point { x: xx, y: yy } if xx == yy => f"diag {xx}"
        _ => "other"

fn fl(f: Flag) -> str:
    match f:
        Flag { on: true, n } => f"on {n}"
        Flag { on: false, n: 3 } => "off3"
        _ => "off-other"

fn ch(c: Ch) -> str:
    match c:
        Ch { c: 'a', n } => f"a {n}"
        Ch { c: 'b', .. } => "b"
        _ => "ch-other"

fn nm(v: Named) -> str:
    match v:
        Named { name: "bob", n } => f"bob {n}"
        Named { name, n: 2 } => f"{name} two"
        _ => "nm-other"

fn ou(o: Outer) -> str:
    match o:
        Outer { inner: Inner { a: 1, b }, .. } => f"a1 b={b}"
        Outer { t: (2, z), .. } => f"t2 z={z}"
        Outer { o: Some(5), .. } => "some5"
        Outer { o: None, inner: { a, .. }, .. } => f"none a={a}"
        _ => "ou-other"

fn wr(w: Wrap) -> str:
    match w:
        Wrap { p: Point { x: 0, .. }, tag: 'z' } => "x0 z"
        Wrap { p: { y: 9, x }, tag } => f"y9 x={x} tag={tag}"
        Wrap { tag: 0..=9, .. } => "digit tag"
        _ => "w-other"

fn guard(p: Point) -> str:
    match p:
        Point { x: 0, y } if y > 5 => f"x0 big {y}"
        Point { x: 0, y } => f"x0 small {y}"
        Point { x: 1, y: 1 } | Point { x: 2, y: 2 } => "diag12"
        Point { y: 3, .. } => "y3"
        Point { x: _, y: 4 } => "y4 wild"
        _ => "rest"

fn gpair(q: Pair[i32]) -> str:
    match q:
        Pair { a: 1, b } => f"pa1 {b}"
        Pair { a, b: 2 } => f"pb2 {a}"
        _ => "p-other"

fn at(p: Point) -> str:
    match p:
        whole @ Point { x: 4, .. } => f"at {whole.y}"
        _ => "no-at"

fn iflet(p: &Point) -> str:
    if let Point { x: 5, y } = p:
        return f"iflet {y}"
    "iflet-miss"

fn letelse(p: Point) -> i32:
    let Point { x: 0, y } = p else: return -1
    y

fn stmt_partial(p: Point, out: str) -> str:
    var s = out
    match p:
        Point { x: 8, y } => s = s ++ f"stmt {y}|"
    s

fn byref(ps: &Vec[Point]) -> i32:
    var n = 0
    for Point { x, y } in ps:
        n = n + x * 10 + y
    for { x, .. } in ps:
        n = n + x
    n

// A refutable `for` pattern skips the elements it does not match
// (behav_for_full_patterns); a literal field is part of that test.
fn filtered(ps: &Vec[Point]) -> i32:
    var n = 0
    for Point { x: 0, y } in ps:
        n = n + y
    n

fn xy(x: i32, y: i32): Point { x: x, y: y }

// Exhaustive without a `_` arm: every value is covered by the arms.
fn bytes(b: u8) -> str:
    match b:
        0..=127 => "ascii"
        128..=255 => "high"

fn bools(t: (bool, bool)) -> i32:
    match t:
        (true, _) => 1
        (false, true) => 2
        (false, false) => 3

fn opt(o: Option[bool]) -> i32:
    match o:
        Some(true) => 1
        Some(false) => 2
        None => 3

fn main:
    print("point: " ++ pt(xy(1, 7)) ++ "|" ++ pt(xy(0, 7)) ++ "|" ++ pt(xy(-1, 4)) ++ "|" ++ pt(xy(3, 9)) ++ "|" ++ pt(xy(3, 8)) ++ "|" ++ pt(xy(7, 8)) ++ "|" ++ pt(xy(9, 0)) ++ "|" ++ pt(xy(6, 6)) ++ "|")
    print("flag: " ++ fl(Flag { on: true, n: 1 }) ++ "|" ++ fl(Flag { on: false, n: 3 }) ++ "|" ++ fl(Flag { on: false, n: 4 }) ++ "|")
    print("char: " ++ ch(Ch { c: 'a', n: 1 }) ++ "|" ++ ch(Ch { c: 'b', n: 1 }) ++ "|" ++ ch(Ch { c: 'z', n: 1 }) ++ "|")
    print("str: " ++ nm(Named { name: "bob", n: 1 }) ++ "|" ++ nm(Named { name: "al", n: 2 }) ++ "|" ++ nm(Named { name: "al", n: 3 }) ++ "|")
    var o = "nested: "
    o = o ++ ou(Outer { inner: Inner { a: 1, b: 2 }, t: (0, 0), o: Some(5) }) ++ "|"
    o = o ++ ou(Outer { inner: Inner { a: 0, b: 2 }, t: (2, 8), o: Some(5) }) ++ "|"
    o = o ++ ou(Outer { inner: Inner { a: 0, b: 2 }, t: (0, 8), o: Some(5) }) ++ "|"
    o = o ++ ou(Outer { inner: Inner { a: 4, b: 2 }, t: (0, 8), o: None }) ++ "|"
    o = o ++ ou(Outer { inner: Inner { a: 4, b: 2 }, t: (0, 8), o: Some(6) }) ++ "|"
    print(o)
    var w = "wrap: "
    w = w ++ wr(Wrap { p: Point { x: 0, y: 1 }, tag: 'z' }) ++ "|"
    w = w ++ wr(Wrap { p: Point { x: 0, y: 9 }, tag: 'q' }) ++ "|"
    w = w ++ wr(Wrap { p: Point { x: 3, y: 1 }, tag: 5 }) ++ "|"
    w = w ++ wr(Wrap { p: Point { x: 3, y: 1 }, tag: 50 }) ++ "|"
    print(w)
    print("guard: " ++ guard(xy(0, 9)) ++ "|" ++ guard(xy(0, 2)) ++ "|" ++ guard(xy(2, 2)) ++ "|" ++ guard(xy(1, 2)) ++ "|" ++ guard(xy(7, 3)) ++ "|" ++ guard(xy(7, 4)) ++ "|" ++ guard(xy(7, 5)) ++ "|")
    print("generic: " ++ gpair(Pair { a: 1, b: 5 }) ++ "|" ++ gpair(Pair { a: 3, b: 2 }) ++ "|" ++ gpair(Pair { a: 3, b: 3 }) ++ "|")
    print("at: " ++ at(Point { x: 4, y: 11 }) ++ "|" ++ at(Point { x: 5, y: 11 }) ++ "|")
    print("if-let: " ++ iflet(Point { x: 5, y: 6 }) ++ "|" ++ iflet(Point { x: 4, y: 6 }) ++ "|")
    print(f"let-else: {letelse(Point { x: 0, y: 7 })}|{letelse(Point { x: 1, y: 7 })}|")
    print(stmt_partial(Point { x: 9, y: 2 }, stmt_partial(Point { x: 8, y: 1 }, "stmt: ")))
    let ps: Vec[Point] = [Point { x: 1, y: 2 }, Point { x: 3, y: 4 }, Point { x: 0, y: 5 }]
    print(f"for: {byref(ps)}|{filtered(ps)}|")
    print(f"exhaustive: {bytes(3)}|{bytes(200)}|{bools((false, true))}|{opt(Some(false))}|")
