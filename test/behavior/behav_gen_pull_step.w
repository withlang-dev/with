//! expect-stdout: 7 49 343
//! expect-stdout: end end
//! expect-stdout: first=alpha-3
//! expect-stdout: rest=beta-5,gamma-7
//! expect-stdout: parser: 11 then 22 33
//! expect-stdout: joined=abab|cdcd

// D69 (§13.4 Pulling): `g.pull()` is an owned Iter[T]; each next() resumes
// the generator on its own fiber and returns Some(element) per yield, then
// None at the end, and None again after that. A partly consumed pulled
// generator can be kept in a struct and stepped later, and a pulled
// generator is an ordinary Iter for `for`.
use std.task.Pulled

gen fn powers(base: i64, count: i32) -> i64:
    var v = base
    for _ in 0..count:
        yield v
        v = v * base

gen fn tagged(names: Vec[str]) -> str:
    var n = 3
    for name in names:
        yield f"{name}-{n}"
        n += 2

gen fn tokens(text: str) -> i32:
    for part in text.split(","):
        yield part.len() as i32 * 11

type Parser {
    toks: Pulled[i32],
}

impl Parser:
    mut fn take(): self.toks.next().unwrap()

gen fn doubled(words: Vec[str]) -> str:
    for w in words:
        yield w ++ w

fn main:
    var p = powers(7, 3).pull()
    let a = p.next().unwrap()
    let b = p.next().unwrap()
    let c = p.next().unwrap()
    print(f"{a} {b} {c}")
    let e1 = if p.next().is_none(): "end" else: "more"
    let e2 = if p.next().is_none(): "end" else: "more"
    print(f"{e1} {e2}")

    var t = tagged(["alpha", "beta", "gamma"]).pull()
    print(f"first={t.next().unwrap()}")
    var rest = ""
    for s in t:
        rest = if rest.len() == 0: s else: rest ++ "," ++ s
    print(f"rest={rest}")

    var parser = Parser { toks: tokens("a,bb,ccc").pull() }
    let head = parser.take()
    let second = parser.take()
    let third = parser.take()
    print(f"parser: {head} then {second} {third}")

    var w = doubled(["ab", "cd"]).pull()
    var joined = ""
    // `match`, not `let … else: break`: #1733.
    while true:
        match w.next():
            None => break
            Some(x) => joined = if joined.len() == 0: x else: joined ++ "|" ++ x
    print(f"joined={joined}")
