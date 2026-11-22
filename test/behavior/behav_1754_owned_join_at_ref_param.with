//! expect-stdout: 3 3 4 1 6
//! expect-stdout: 42 7 9
// #1754 (§3.8, D22 §8.2 rules 2 and 5): an argument meets a `&T` parameter
// through auto-ref, so an if/match argument is a join its arms decide: owned
// arms give an owned result the call borrows (a literal arm is the owned
// `str`, a numeric arm takes T's width), view arms keep a view. The `&T`
// expectation used to anchor the join as a reference and every owned arm
// failed "if expression of type `str` cannot produce `&str`".

fn f(s: &str) -> i64: s.len()
fn g(n: &i64) -> i64: *n + 1

type W { n: i64 }
extend W:
    fn label(self: &Self, s: &str) -> i64: s.len() + self.n

fn main:
    let a = "x"
    let b = "longer"
    let c = true
    let k = 2
    let one = f(a ++ "yy")
    let owned = f(if c: a ++ "yy" else: a ++ "z")
    let literal_arm = f(if not c: a ++ "yy" else: "four")
    let views = f(if c: &a else: &b)
    let matched = f(match k:
        1 => a ++ "1"
        2 => "twenty"
        _ => a)
    print(f"{one} {owned} {literal_arm} {views} {matched}")
    let w = W { n: 5 }
    let widened = g(if c: 41 else: 40)
    let method_owned = w.label(if c: a ++ "y" else: "zz")
    let method_match = w.label(match k:
        2 => "four"
        _ => a)
    print(f"{widened} {method_owned} {method_match}")
