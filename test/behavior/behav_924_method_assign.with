//! expect-stdout: [a b] HELLO 1 [x] 7 3

// #924 (§4.2.5): `x .= f(args)` is `x = x.f(args)` with the place `x`
// evaluated once.
type Counter { n: i32 }

impl Counter:
    fn plus(k: i32) -> Counter: Counter { n: self.n + k }

type Holder { name: str }

var calls = 0

fn idx() -> i32:
    calls += 1
    0

fn main:
    var line = "  a b "
    line .= trim()
    var word = "hello"
    word .= to_upper()
    var xs = ["  x "]
    xs[idx()] .= trim()
    var c = Counter { n: 4 }
    c .= plus(3)
    var h = Holder { name: " ab " }
    h.name .= trim()
    h.name .= replace("b", "bc")
    print(f"[{line}] {word} {calls} [{xs[0]}] {c.n} {h.name.len()}")
