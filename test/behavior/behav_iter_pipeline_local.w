//! expect-stdout: ok

fn make_iter(xs: &Vec[i32]) -> VecIter[i32]:
    xs.iter()

fn sum_iter(iter: VecIter[i32]) -> i32:
    var total = 0
    var done = false
    while not done:
        let item = iter.next()
        if item.is_some():
            total = total + item.unwrap()
        else:
            done = true
    total

fn make_filtered(xs: &Vec[i32]) -> FilterIter[VecIter[i32], i32]:
    xs.iter().filter(x => x % 2 == 0)

fn main:
    let xs: Vec[i32] = Vec.new()
    xs.push(1)
    xs.push(2)
    xs.push(3)
    xs.push(4)
    assert(sum_iter(make_iter(&xs)) == 10)
    let evens = make_filtered(&xs) |> collect[Vec]()
    assert(evens.len() == 2)
    assert(evens.get(0) == 2)
    assert(evens.get(1) == 4)
    print("ok")
