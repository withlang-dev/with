//! expect-stdout: ok

fn doubled(xs: &Vec[i32]) -> Vec[i32]:
    xs.map(it * 2)

fn main:
    var xs: Vec[i32] = Vec.new()
    xs.push(1)
    xs.push(2)
    xs.push(3)
    var sum = 0
    for v in xs:
        sum = sum + v
    assert(sum == 6)
    assert(xs.len() == 3)
    for v in xs:
        sum = sum + v
    assert(sum == 12)
    var rsum = 0
    for v in doubled(&xs):
        rsum = rsum + v
    assert(rsum == 12)
    var names: Vec[str] = Vec.new()
    names.push("a")
    names.push("bb")
    var total = 0
    for n in names:
        total = total + n.len() as i32
    assert(total == 3)
    assert(names.len() == 2)
    print("ok")
