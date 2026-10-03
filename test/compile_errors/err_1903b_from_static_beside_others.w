//! expect-error: `pick` declares `from static` beside other origins

// #1903 (§21.1 rule 6, spec v7.18): `from static` states that the returned
// view has no other origin, so it is listed alone.

fn pick(p: &Vec[i32]) -> &i32 from static, p: &p[0]

fn main:
    var x: Vec[i32] = Vec.new()
    x.push(1)
    print(*pick(&x))
