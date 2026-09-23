//! expect-stdout: miss
//! expect-stdout: -1 1
//! expect-stdout: braced miss
//! expect-stdout: -2 1
//! expect-stdout: multiline miss
//! expect-stdout: -3 1
//! expect-stdout: -4 1
//! expect-stdout: option miss
//! expect-stdout: -5 1
//! expect-stdout: loud miss
//! expect-stdout: i0
//! expect-stdout: i1
//! expect-stdout: -6 1
//! expect-stdout: not named
//! expect-stdout: not empty
//! expect-stdout: 3 0 1
//! expect-stdout: tuple miss
//! expect-stdout: 3 -1
//! expect-stdout: skip
//! expect-stdout: skip
//! expect-stdout: 4
//! expect-stdout: done
//! expect-stdout: 2

// #1382: the else branch of `let PATTERN = EXPR else` takes every body form
// a block takes (§29.13): inline item, indented multi-statement block, braced
// inline and braced multi-line, and a bare `else` takes one diverging
// expression on the same line (§9.7, D58); on the next line it needs `else:`.

enum Shape:
    Named(i32)
    Empty

fn int_or_err(k: i32) -> Result[i32, str]:
    if k == 0: return Err("none".clone())
    k

fn indented(k: i32) -> i32:
    let Ok(v) = int_or_err(k) else:
        print("miss")
        return -1
    v

fn braced(o: Option[i32]) -> i32:
    let Some(v) = o else { print("braced miss"); return -2 }
    v

fn braced_multiline(o: Option[i32]) -> i32:
    let Some(v) = o else {
        print("multiline miss")
        return -3
    }
    v

fn bare_inline(o: Option[i32]) -> i32:
    let Some(v) = o else return -4
    v

fn indented_option(o: Option[i32]) -> i32:
    let Some(v) = o else:
        print("option miss")
        return -5
    v

fn nested_control(o: Option[i32], loud: bool) -> i32:
    let Some(v) = o else:
        if loud:
            print("loud miss")
        let Some(_w) = Some(1) else: return -7
        for i in 0..2: print(f"i{i}")
        return -6
    v

fn qualified(s: Shape) -> i32:
    let Shape.Named(n) = s else:
        print("not named")
        return 0
    n

fn shorthand_unit(s: Shape) -> i32:
    let .Empty = s else:
        print("not empty")
        return 1
    0

fn tuple(t: (Option[i32], i32)) -> i32:
    let (Some(a), b) = t else:
        print("tuple miss")
        return -1
    a + b

fn below(n: i32) -> Option[i32]: if n < 2: Some(n) else: None

fn main:
    print(f"{indented(0)} {indented(1)}")
    print(f"{braced(None)} {braced(Some(1))}")
    print(f"{braced_multiline(None)} {braced_multiline(Some(1))}")
    print(f"{bare_inline(None)} {bare_inline(Some(1))}")
    print(f"{indented_option(None)} {indented_option(Some(1))}")
    print(f"{nested_control(None, true)} {nested_control(Some(1), true)}")
    print(f"{qualified(Shape.Named(3))} {qualified(Shape.Empty)} {shorthand_unit(Shape.Named(1))}")
    print(f"{tuple((Some(1), 2))} {tuple((None, 2))}")
    var total = 0
    for o in [Some(1), None, Some(3), None, Some(100)]:
        let Some(v) = o else:
            print("skip")
            continue
        if v > 50: break
        total = total + v
    print(f"{total}")
    var n = 0
    loop:
        let Some(_) = below(n) else:
            print("done")
            break
        n = n + 1
    print(f"{n}")
