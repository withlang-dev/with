// Test typed closure parameters: |x: i32, y: i32| -> i32

fn main -> i32:
    // Typed closure with return type
    let double = |x: i32| -> i32 x * 2
    let r1 = double(5)
    // Untyped (backwards compatible)
    let inc = |x| x + 1
    let r2 = inc(9)
    // Typed without return annotation
    let add = |a: i32, b: i32| a + b
    let r3 = add(3, 4)
    if r1 == 10 and r2 == 10 and r3 == 7
        0
    else
        1
