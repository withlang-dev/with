//! expect-stdout: ok

fn loop_value_simple -> i32:
    loop:
        break 42

fn loop_value_labeled -> i32:
    'outer loop:
        loop:
            break 'outer 7

fn loop_value_arithmetic -> i32:
    let x = loop:
        break 20
    x + 22

fn loop_tail_expression -> i32:
    loop:
        break 42

fn never_loop_tail -> i32:
    loop:
        let _ = 1

fn unit_loop_plain_break:
    loop:
        break

fn main:
    assert(loop_value_simple() == 42)
    assert(loop_value_labeled() == 7)
    assert(loop_value_arithmetic() == 42)
    assert(loop_tail_expression() == 42)
    unit_loop_plain_break()
    print("ok")
