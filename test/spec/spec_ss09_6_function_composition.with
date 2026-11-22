// Spec test: Section 9.6 — Pipeline and Composition Operators

fn double(x: i32) -> i32: x * 2

fn add1(x: i32) -> i32: x + 1

fn add(x: i32, y: i32) -> i32: x + y

fn test_pipeline_chain:
    assert((5 |> double |> add1) == 11)

fn test_pipeline_extra_args:
    assert((5 |> add(6)) == 11)

fn test_backward_application:
    assert((add1 <| double <| 3) == 7)

fn test_explicit_closure_composition:
    let f = x => add1(double(x))
    assert(f(5) == 11)

fn test_shift_operators_remain_bitwise:
    let flags = 1 << 4
    let high = 0x1200 >> 8
    assert(flags == 16)
    assert(high == 18)
