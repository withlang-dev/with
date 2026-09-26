//! expect-debug-alloc: leak count=0
//! expect-stdout: 6

// #1548: a generator's owned named local is dropped once when the generator
// is exhausted — by the next body's scope exit — and the generator value's
// own drop then finds the state field blanked.
fn words() -> Vec[str]:
    var v: Vec[str] = Vec.new()
    v.push("a".clone())
    v.push("bb".clone())
    v.push("ccc".clone())
    v
gen fn each() -> str:
    let v = words()
    var i = 0
    while i < v.len() as i32:
        yield v[i].clone()
        i += 1
fn main:
    var n = 0
    for w in each():
        n = n + w.len() as i32
    print(n)
