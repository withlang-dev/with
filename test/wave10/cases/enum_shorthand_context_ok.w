type A = Same | OnlyA
type B = Same | OnlyB
type Holder = { a: A, b: B }

fn default_a -> A: .Same
fn default_b -> B: .Same

fn score_a(v: A) -> i32:
    match v
        .Same -> 1
        .OnlyA -> 2

fn main -> i32:
    let a: A = .Same
    let b: B = .Same
    let h = Holder { a: .Same, b: .Same }
    let call_score = score_a(.Same)
    let ok =
        score_a(a) == 1 and default_a() == a and default_b() == b and
        h.a == a and h.b == b and call_score == 1
    if ok then 0 else 1
