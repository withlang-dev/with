//! expect-stdout: 1 4 5
//! expect-stdout: 2 4 5
//! expect-stdout: 3 4 5
//! expect-stdout: 4 7 8
//! expect-stdout: 5 1 0
//! expect-stdout: 6 4 5
//! expect-stdout: 7 1 0
//! expect-stdout: 8 7 8
//! expect-stdout: 9 4 5
//! expect-stdout: 10 3 4 5
//! expect-stdout: 11 3 4 5
//! expect-stdout: 12 3 4
//! expect-stdout: 13 9 9
//! expect-stdout: 14 4
//! expect-stdout: 15 5 0
//! expect-stdout: 16 hi 2
//! expect-stdout: 17 4 5
//! expect-stdout: 18 2 3
//! expect-stdout: 18 4 5
//! expect-stdout: 19 4 5
//! expect-stdout: 20 4 5
//! expect-stdout: 21 9 -1
//! expect-stdout: 22 9 0
//! expect-stdout: 23 4 5

// #1349: a destructuring `let`, `for`, and `with` check their subject as a
// value. The subject was checked in the enclosing statement's context, so an
// `if` subject inside a void function took the statement arm, typed as void,
// and a tuple pattern reported "tuple pattern requires tuple subject".

fn lc(b: i32) -> (i32, i32): (b + 1, b + 2)
fn nest(b: i32) -> ((i32, i32), i32): ((b, b + 1), b + 2)
fn owned(n: i32) -> (str, i32): ("h" ++ "i", n)

// A non-void function: the subject is a value here too.
fn sum_pair(b: i32) -> i32:
    let (x, y) = if b > 0: lc(b) else: (0, 0)
    x + y

fn first_some(b: i32) -> i32:
    let .Some(v) = if b > 0: Some(b * 3) else: None else: return -1
    v

fn main:
    let b = 3
    let (a1, b1) = if b > 0: lc(b) else: (1, 0)
    print(f"1 {a1} {b1}")
    let (a2, b2) = if b < 0: (1, 0) else: lc(b)
    print(f"2 {a2} {b2}")
    let (a3, b3) = if b > 0: lc(b) else: lc(0)
    print(f"3 {a3} {b3}")
    let (a4, b4) = if b > 0: (7, 8) else: (1, 0)
    print(f"4 {a4} {b4}")
    let (a5, b5) = if b < 0: lc(b) else: (1, 0)
    print(f"5 {a5} {b5}")
    let (a6, b6) = match b:
        3 => lc(b)
        _ => (1, 0)
    print(f"6 {a6} {b6}")
    let (a7, b7) = match b:
        3 => (1, 0)
        _ => lc(b)
    print(f"7 {a7} {b7}")
    let (a8, b8) = {
        let z = b * 2
        (z + 1, z + 2)
    }
    print(f"8 {a8} {b8}")
    let (a9, b9) = lc(b)
    print(f"9 {a9} {b9}")
    let ((p10, q10), r10) = if b > 0: nest(b) else: ((0, 0), 0)
    print(f"10 {p10} {q10} {r10}")
    let ((p11, q11), r11) = if b < 0: ((0, 0), 0) else: nest(b)
    print(f"11 {p11} {q11} {r11}")
    let (p12, q12) = if b > 0: nest(b).0 else: (1, 0)
    print(f"12 {p12} {q12}")
    let (a13, b13) = if b > 5: (1, 1) else if b > 4: lc(b) else: (9, 9)
    print(f"13 {a13} {b13}")
    let (a14, _) = if b > 0: lc(b) else: (1, 0)
    print(f"14 {a14}")
    let (a15, b15) = if b > 0: (lc(b).1, 0) else: (1, 0)
    print(f"15 {a15} {b15}")
    let (s16, n16) = if b > 0: owned(2) else: ("n" ++ "o", 0)
    print(f"16 {s16} {n16}")
    let (a17, b17) = if b > 0:
        lc(b)
    else:
        (1, 0)
    print(f"17 {a17} {b17}")
    var v: Vec[(i32, i32)] = Vec.new()
    v.push(lc(1))
    v.push(if b > 0: lc(b) else: (1, 0))
    let w: Vec[(i32, i32)] = Vec.new()
    for (x, y) in if b > 0: v else: w:
        print(f"18 {x} {y}")
    with if b > 0: lc(b) else: (1, 0) as (x, y):
        print(f"19 {x} {y}")
    with if b > 0: lc(b) else: (1, 0) as t:
        print(f"20 {t.0} {t.1}")
    print(f"21 {first_some(b)} {first_some(-b)}")
    print(f"22 {sum_pair(b)} {sum_pair(-b)}")
    with t(if b > 0: lc(b) else: (1, 0)):
        print(f"23 {t.0} {t.1}")
