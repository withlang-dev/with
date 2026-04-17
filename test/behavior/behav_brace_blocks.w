//! expect-stdout: all brace block tests passed

fn add(a: i32, b: i32) -> i32 {
    a + b
}

fn factorial(n: i32) -> i32 {
    if n <= 1 {
        1
    } else {
        n * factorial(n - 1)
    }
}

fn classify(x: i32) -> str {
    if x > 100 {
        "big"
    } else if x > 10 {
        "medium"
    } else {
        "small"
    }
}

fn sum_to(n: i32) -> i32 {
    var total = 0
    var i = 1
    while i <= n {
        total = total + i
        i = i + 1
    }
    total
}

fn count_items() -> i32 {
    var count = 0
    for x in 0..5 {
        count = count + 1
    }
    count
}

fn loop_break() -> i32 {
    var i = 0
    loop {
        i = i + 1
        if i >= 10 {
            break
        }
    }
    i
}

fn main {
    assert(add(3, 4) == 7)
    assert(factorial(5) == 120)
    assert(classify(200) == "big")
    assert(classify(50) == "medium")
    assert(classify(5) == "small")
    assert(sum_to(10) == 55)
    assert(count_items() == 5)
    assert(loop_break() == 10)
    print("all brace block tests passed")
}
