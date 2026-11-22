//! expect-stdout: ok

fn test_tuple_destructure:
    let pairs = [(1, 2), (3, 4), (5, 6)]
    var sum_a = 0
    var sum_b = 0
    for (a, b) in pairs:
        sum_a = sum_a + a
        sum_b = sum_b + b
    assert(sum_a == 9)
    assert(sum_b == 12)

fn test_wildcard_destructure:
    let pairs = [(10, 20), (30, 40)]
    var sum = 0
    for (_, v) in pairs:
        sum = sum + v
    assert(sum == 60)

fn test_triple_destructure:
    let triples = [(1, 2, 3), (4, 5, 6)]
    var sum = 0
    for (a, b, c) in triples:
        sum = sum + a + b + c
    assert(sum == 21)

fn main:
    test_tuple_destructure()
    test_wildcard_destructure()
    test_triple_destructure()
    print("ok")
