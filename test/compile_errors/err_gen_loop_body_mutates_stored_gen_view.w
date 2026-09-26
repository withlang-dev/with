//! expect-check-fail: cannot mutate `v` while `g` is a live view into it

// D69 (§13.4, §21.1, #1734): a generator value bound before the loop keeps its views live
// through the loop that consumes it.
gen fn over(xs: &Vec[i32]) -> i32:
    for x in xs:
        yield x

fn main:
    var v: Vec[i32] = [1, 2, 3]
    let g = over(&v)
    for x in g:
        v.push(x)
    print(v.len())
