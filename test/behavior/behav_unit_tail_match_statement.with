//! expect-stdout: 5 3
//! expect-stdout: 5 3
//! expect-stdout: 0 4
//! expect-stdout: 7 1
//! expect-stdout: ok

// D43 / #1711: `-> Unit` makes a function's tail statement position in every
// body spelling. A single-statement body is its own tail, so a tail `match`
// there is a statement: its arms are statements — an arm's else-less `if`
// is fine — and their types are never joined. The block spelling already
// was; the single-statement one was checked as a value (the else-less `if`
// was refused, then the float and Unit arms failed to join).

pub enum K { | A | B }
impl Copy for K
pub type G { frozen: f64 = 0.0, health: i32 = 3 }
extend G:
    // The issue's method, spelled with the `-> Unit` the D43 remedy names.
    fn f(mut self: Self, k: K) -> Unit:
        match k:
            .A => { self.frozen = 5.0 }
            .B => {
                self.health += 1
                if self.health > 3: self.health = 3
            }

var frozen = 0.0
var health = 3
fn free(k: K) -> Unit:
    match k:
        .A => frozen = 7.0
        .B =>
            health += 1
            if health > 3: health = 1

fn main:
    var g = G {}
    g.f(.A)
    print(f"{g.frozen} {g.health}")
    g.f(.B)
    print(f"{g.frozen} {g.health}")
    var h = G { frozen: 0.0, health: 3 }
    h.health = 3
    h.f(.B)
    h.health += 1
    print(f"{h.frozen} {h.health}")
    free(.A)
    free(.B)
    print(f"{frozen} {health}")
    // A closure whose expected type returns Unit has the same statement tail.
    let bump: fn(K) -> Unit = (k) =>
        match k:
            .A => print("a")
            .B =>
                health += 1
                if health > 3: health = 3
    bump(.B)
    assert(health == 2)
    print("ok")
