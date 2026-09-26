//! expect-stdout: twice 42 abab
//! expect-stdout: pairs 1z 1z | x7
//! expect-stdout: over 15 ace
//! expect-stdout: pipeline 12 12
//! expect-stdout: comp 5 6 7
//! expect-stdout: read 30
//! expect-stdout: mut 6 7 8 now 8
//! expect-stdout: move d0d1
//! expect-stdout: explicit self 18
//! expect-stdout: generic owner pq
//! expect-stdout: str [abc][def] from abcdef
//! expect-stdout: i32 321

// D69 (§13.4, #1724): a generic `gen fn` specializes like any generic
// function — each specialization has its own generator value, producer and
// `each` — and a `gen fn` may be a method. The generator value holds the
// receiver like any other argument: a borrowed receiver (`fn`, `mut fn`) as
// a view of the caller's place, so the producer reads and writes the
// caller's value; a `move fn` receiver as an owned argument.
use std.generators.{map, take, collect}

gen fn twice[T: Clone](x: T) -> T:
    yield x.clone()
    yield x

gen fn pairs[A: Clone, B: Clone](a: A, b: B, n: i32) -> (A, B):
    for _ in 0..n:
        yield (a.clone(), b.clone())

gen fn over[T](xs: &Vec[T]) -> &T:
    for x in xs:
        yield x

type Counter {
    n: i32,
    hits: i32,
}

impl Counter:
    gen fn upto() -> i32:
        for i in 0..self.n:
            yield i
    gen mut fn tick(times: i32) -> i32:
        for _ in 0..times:
            self.hits += 1
            yield self.hits
    gen move fn drain() -> str:
        for i in 0..self.n:
            yield f"d{i}"

type Tree {
    vals: Vec[i32],
}

gen fn Tree.walk(self: &Tree) -> i32:
    for v in self.vals:
        yield v

type Stack[T] {
    items: Vec[T],
}

impl[T] Stack[T]:
    gen fn each_item() -> &T:
        for x in self.items:
            yield x

extend str:
    gen fn halves() -> str:
        let n = self.len() / 2
        yield self.slice(0, n as i64)
        yield self.slice(n as i64, self.len() as i64)

extend i32:
    gen fn countdown() -> i32:
        var i: i32 = self
        while i > 0:
            yield i
            i -= 1

fn main:
    var total = 0
    for v in twice(21):
        total += v
    var text = ""
    for w in twice("ab".clone()):
        text = text ++ w
    print(f"twice {total} {text}")

    var ps = ""
    for (a, b) in pairs(1, "z".clone(), 2):
        ps = ps ++ f" {a}{b}"
    for (a, b) in pairs("x".clone(), 7, 5):
        ps = ps ++ f" | {a}{b}"
        break
    print(f"pairs{ps}")

    let nums: Vec[i64] = [4, 5, 6]
    var sum: i64 = 0
    for x in over(&nums):
        sum += x
    let letters: Vec[str] = ["a".clone(), "c".clone(), "e".clone()]
    var joined = ""
    for s in over(&letters):
        joined = joined ++ s
    print(f"over {sum} {joined}")

    let firsts = pairs(3, 4, 9) |> map(p => p.0 * p.1) |> take(2) |> collect[Vec]()
    print(f"pipeline {firsts[0]} {firsts[1]}")
    let comp = [x + 1 for x in over(&nums)]
    print(f"comp {comp[0]} {comp[1]} {comp[2]}")

    let c = Counter { n: 3, hits: 0 }
    var r = 0
    for i in c.upto():
        r += i * 10
    print(f"read {r}")
    var m = Counter { n: 0, hits: 5 }
    var seen = ""
    for h in m.tick(3):
        seen = seen ++ f" {h}"
    print(f"mut{seen} now {m.hits}")
    let d = Counter { n: 2, hits: 0 }
    var ds = ""
    for x in d.drain():
        ds = ds ++ x
    print(f"move {ds}")

    let t = Tree { vals: [5, 6, 7] }
    var tsum = 0
    for v in t.walk():
        tsum += v
    print(f"explicit self {tsum}")
    let st: Stack[str] = Stack { items: ["p".clone(), "q".clone()] }
    var ss = ""
    for x in st.each_item():
        ss = ss ++ x
    print(f"generic owner {ss}")

    let s = "abcdef".clone()
    var halves = ""
    for h in s.halves():
        halves = halves ++ "[" ++ h ++ "]"
    print(f"str {halves} from {s}")
    let k = 3
    var cd = ""
    for i in k.countdown():
        cd = cd ++ f"{i}"
    print(f"i32 {cd}")
