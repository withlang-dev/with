// Wave 7: async/generator constructs are still lowered into regular MIR CFG.

async fn async_add(x: i32) -> i32:
    x + 1

gen fn up_to(n: i32) -> i32:
    var i: i32 = 0
    while i < n:
        yield i
        i = i + 1

fn main -> i32:
    let task = async_add(4)
    let got = task.await

    var iter = up_to(3)
    var sum: i32 = 0
    for v in iter:
        sum += v

    assert(got == 5)
    assert(sum == 3)
    0
