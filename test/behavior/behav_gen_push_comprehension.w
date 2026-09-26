//! expect-stdout: doubled 0 2 4 6 8
//! expect-stdout: odd squares 1 9 25 49
//! expect-stdout: pairs 01 02 12
//! expect-stdout: nested 00 10 11 20 21 22
//! expect-stdout: range after gen 0 10 11 20 21 22
//! expect-stdout: set 4
//! expect-stdout: map 1:ten 2:twenty 3:thirty
//! expect-stdout: labels item-0|item-1|item-2
//! expect-stdout: some 2 6
//! expect-stdout: offset 107 108 109
//! expect-stdout: stored 3 4 5

// D69 (§13.4, §13.6, #1727): a comprehension clause `for x in g` over a
// generator consumes it like a `for` loop: the rest of the comprehension —
// the clause's filter, the later clauses and the element — runs at each
// `yield`. Generator clauses mix with range clauses in either order, nest,
// build sets and maps, take views of the generator's own locals (cloned into
// the collection), use refutable patterns, and read enclosing bindings.
use std.collections.{BTreeMap, BTreeSet}

gen fn upto(n: i32) -> i32:
    for i in 0..n:
        yield i

gen fn labels(count: i32) -> &str:
    var buf = ""
    for i in 0..count:
        buf = f"item-{i}"
        yield &buf

gen fn maybe(n: i32) -> Option[i32]:
    for i in 0..n:
        yield if i % 2 == 1: Some(i * 2) else: None

fn join(v: &Vec[i32]) -> str:
    var s = ""
    for x in v:
        s = s ++ f" {x}"
    s

fn main:
    let doubled = [x * 2 for x in upto(5)]
    print(f"doubled{join(&doubled)}")
    let odd_squares = [x * x for x in upto(8) if x % 2 == 1]
    print(f"odd squares{join(&odd_squares)}")
    let pairs = [a * 10 + b for a in upto(3) for b in upto(3) if a < b]
    var ptext = "pairs"
    for p in pairs:
        ptext = ptext ++ f" {p / 10}{p % 10}"
    print(ptext)
    let nested = [a * 10 + b for a in upto(3) for b in upto(a + 1)]
    var ntext = "nested"
    for n in nested:
        ntext = ntext ++ f" {n / 10}{n % 10}"
    print(ntext)
    let mixed = [a * 10 + b for a in 0..3 for b in upto(a + 1)]
    print(f"range after gen{join(&mixed)}")
    let set: BTreeSet[i32] = [x % 4 for x in upto(10)]
    print(f"set {set.len()}")
    let names: BTreeMap[i32, str] = [x: (if x == 1: "ten" else if x == 2: "twenty" else: "thirty") for x in upto(4) if x > 0]
    var mtext = "map"
    for (k, v) in names:
        mtext = mtext ++ f" {k}:{v}"
    print(mtext)
    let kept = [s.clone() for s in labels(3)]
    var ltext = ""
    for s in kept:
        ltext = ltext ++ (if ltext.len() > 0: "|" else: "") ++ s
    print(f"labels {ltext}")
    let some = [v for Some(v) in maybe(4)]
    print(f"some{join(&some)}")
    let base = 100
    let bump = 7
    let offset = [base + bump + x for x in upto(3)]
    print(f"offset{join(&offset)}")
    let g = upto(6)
    let stored = [x for x in g if x >= 3]
    print(f"stored{join(&stored)}")
