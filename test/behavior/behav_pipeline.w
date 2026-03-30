//! expect-stdout: ok

// Behavior test: pipeline operator (|>)
// Tests: basic pipeline, chained pipeline

fn double(x: i32) -> i32:
    x * 2

fn add_one(x: i32) -> i32:
    x + 1

fn negate(x: i32) -> i32:
    -x

fn test_basic_pipeline:
    let result = 5 |> double
    assert(result == 10)

fn test_pipeline_chain:
    let result = 3 |> double |> add_one
    assert(result == 7)

fn test_pipeline_three_stages:
    let result = 4 |> add_one |> double |> negate
    assert(result == -10)

fn main:
    test_basic_pipeline()
    test_pipeline_chain()
    test_pipeline_three_stages()
    print("ok")
