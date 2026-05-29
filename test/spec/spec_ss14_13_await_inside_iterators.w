//! expect-stdout: ok

async fn double(n: i32) -> i32:
    n * 2

async fn count_for(id: i32) -> i32:
    id + 1

fn numbers -> Vec[i32]:
    let values: Vec[i32] = Vec.new()
    values.push(1)
    values.push(2)
    values.push(3)
    values

fn test_await_inside_map:
    let doubled = numbers().map(n => double(n).await)
    assert(doubled.len() == 3)
    assert(doubled.get(0) == 2)
    assert(doubled.get(1) == 4)
    assert(doubled.get(2) == 6)

fn test_await_inside_fold:
    let total = numbers().fold(0, (sum, id) => sum + count_for(id).await)
    assert(total == 9)

fn main:
    test_await_inside_map()
    test_await_inside_fold()
    print("ok")
