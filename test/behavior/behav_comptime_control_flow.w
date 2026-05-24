//! expect-stdout: ok

comptime fn test_if_true() -> i32:
    if true:
        42
    else:
        0

comptime fn test_if_false() -> i32:
    if false:
        0
    else:
        99

comptime fn test_if_chain() -> i32:
    let x = 5
    if x > 10:
        1
    else if x > 3:
        2
    else:
        3

comptime fn test_for_sum() -> i32:
    var sum = 0
    for i in 0..5:
        sum = sum + i
    sum

comptime fn test_for_nested() -> i32:
    var total = 0
    for i in 0..3:
        for j in 0..3:
            total = total + 1
    total

comptime fn test_while_basic() -> i32:
    var n = 0
    while n < 10:
        n = n + 1
    n

comptime fn test_while_break() -> i32:
    var n = 0
    while true:
        n = n + 1
        if n == 7:
            break
    n

comptime fn test_for_break() -> i32:
    var result = 0
    for i in 0..100:
        if i == 5:
            break
        result = result + 1
    result

comptime fn test_for_continue() -> i32:
    var sum = 0
    for i in 0..10:
        if i % 2 == 0:
            continue
        sum = sum + i
    sum

comptime fn test_early_return() -> i32:
    for i in 0..100:
        if i == 3:
            return 42
    0

comptime fn test_match_basic() -> i32:
    let x = 2
    match x:
        1 => 10
        2 => 20
        3 => 30
        _ => 0

const IF_TRUE: i32 = comptime test_if_true()
const IF_FALSE: i32 = comptime test_if_false()
const IF_CHAIN: i32 = comptime test_if_chain()
const FOR_SUM: i32 = comptime test_for_sum()
const FOR_NESTED: i32 = comptime test_for_nested()
const WHILE_BASIC: i32 = comptime test_while_basic()
const WHILE_BREAK: i32 = comptime test_while_break()
const FOR_BREAK: i32 = comptime test_for_break()
const FOR_CONTINUE: i32 = comptime test_for_continue()
const EARLY_RET: i32 = comptime test_early_return()
const MATCH_BASIC: i32 = comptime test_match_basic()

fn main:
    assert(IF_TRUE == 42)
    assert(IF_FALSE == 99)
    assert(IF_CHAIN == 2)
    assert(FOR_SUM == 10)
    assert(FOR_NESTED == 9)
    assert(WHILE_BASIC == 10)
    assert(WHILE_BREAK == 7)
    assert(FOR_BREAK == 5)
    assert(FOR_CONTINUE == 25)
    assert(EARLY_RET == 42)
    assert(MATCH_BASIC == 20)
    print("ok")
