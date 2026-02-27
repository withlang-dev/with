// Tests for the pipeline example

use test.testing

fn double(x: i32) -> i32:
    x * 2

fn add_ten(x: i32) -> i32:
    x + 10

type WorkItem = {
    id: i32,
    payload: i32,
}

type ProcessedItem = {
    id: i32,
    result: i32,
    worker_id: i32,
}

fn process_item(item: WorkItem, worker_id: i32) -> ProcessedItem:
    ProcessedItem {
        id: item.id,
        result: item.payload * 2 + worker_id,
        worker_id: worker_id,
    }

fn count_positive(a: i32, b: i32, c: i32, d: i32, e: i32) -> i32:
    var n = 0
    if a > 0 then n = n + 1 else n = n
    if b > 0 then n = n + 1 else n = n
    if c > 0 then n = n + 1 else n = n
    if d > 0 then n = n + 1 else n = n
    if e > 0 then n = n + 1 else n = n
    n

@[test]
fn test_pipeline_example:
    // Test double
    assert_true(double(0) == 0)
    assert_true(double(5) == 10)
    assert_true(double(-3) == -6)

    // Test add_ten
    assert_true(add_ten(0) == 10)
    assert_true(add_ten(32) == 42)

    // Test pipeline composition
    let r1 = 5 |> double
    assert_true(r1 == 10)

    let r2 = 5 |> double |> add_ten
    assert_true(r2 == 20)

    let r3 = 5 |> double |> add_ten |> double
    assert_true(r3 == 40)

    // Test process_item
    let item = WorkItem { id: 3, payload: 100 }
    let result = process_item(item, 7)
    assert_true(result.id == 3)
    assert_true(result.result == 207)
    assert_true(result.worker_id == 7)

    // Test count_positive
    assert_true(count_positive(1, 2, 3, 4, 5) == 5)
    assert_true(count_positive(0, 0, 0, 0, 0) == 0)
    assert_true(count_positive(10, 0, 20, 0, 30) == 3)
    assert_true(count_positive(-1, -2, 1, 0, 0) == 1)

    // Test pipeline in a loop
    var sum = 0
    for i in 1..5:
        sum = sum + (i |> double |> add_ten)
    assert_true(sum == 60)

