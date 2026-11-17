//! expect-stdout: [A B] 1 [x!] 9 A.B

// #924 (§4.2.5): further method calls after `.=` apply to the result:
// `a .= f().g()` is `a = a.f().g()`, the place `a` evaluated once.
type Counter { n: i32 }

impl Counter:
    fn plus(k: i32) -> Counter: Counter { n: self.n + k }
    fn twice() -> Counter: Counter { n: self.n * 2 }

type Holder { name: str }

var calls = 0

fn idx() -> i32:
    calls += 1
    0

fn main:
    var line = "  a b "
    line .= trim().to_upper()
    var xs = ["  x "]
    xs[idx()] .= trim().replace("x", "x!")
    var c = Counter { n: 1 }
    c .= plus(2).twice().plus(3)
    var h = Holder { name: " a b " }
    h.name .= trim().to_upper().replace(" ", ".")
    print(f"[{line}] {calls} [{xs[0]}] {c.n} {h.name}")
