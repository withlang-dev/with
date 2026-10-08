//! expect-stdout: letters stopped at g
//! expect-stdout: 3:c 5:e 7:g
//! expect-stdout: paired 3

// D69 (§13.4 Pulling): stepping two generators in lockstep — what `zip`
// does — needs each one pulled, and a pulled generator is an ordinary
// Iter[T] to generic code. The shorter one ends the pairing; the longer one,
// dropped mid-sequence when the pairing returns, stops at its yield (its
// defer runs then, naming the last element it handed out).
gen fn odds_from(start: i32, count: i32) -> i32:
    for i in 0..count:
        yield start + 2 * i

gen fn letters(all: Vec[str]) -> str:
    var last = ""
    defer:
        print(f"letters stopped at {last}")
    for s in all:
        last = s
        yield s

fn lockstep[A, B](left: impl Iter[A], right: impl Iter[B]) -> Vec[(A, B)]:
    var l = left
    var r = right
    var out: Vec[(A, B)] = Vec.new()
    // `match`, not `let … else: break`: #1733.
    while true:
        match l.next():
            None => break
            Some(x) =>
                match r.next():
                    None => break
                    Some(y) => out.push((x, y))
    out

fn main:
    let pairs = lockstep(odds_from(3, 3).pull(), letters(["c", "e", "g", "i", "k"]).pull())
    var out = ""
    for (x, s) in pairs:
        out = if out.len() == 0: f"{x}:{s}" else: out ++ f" {x}:{s}"
    print(out)
    print(f"paired {pairs.len()}")
