//! expect-stdout: ok
// Spec test: Section 13.4 — Generators.

gen fn countdown(from: i32) -> i32:
    var i = from
    while i >= 0:
        yield i
        i -= 1

gen fn two_step -> i32:
    var a = 1
    var b = 10
    yield a + b
    a += 1
    b += 10
    yield a + b

gen fn values_from(source: &Vec[i32]) -> i32:
    var i = 0
    while i < source.len() as i32:
        yield source.get(i as i64)
        i += 1

fn forward_values_from(source: &Vec[i32]):
    values_from(source)

fn test_next_resumes_from_each_yield:
    var iter = countdown(3)
    match iter.next():
        Some(v) => assert(v == 3)
        None => assert(false)
    match iter.next():
        Some(v) => assert(v == 2)
        None => assert(false)
    match iter.next():
        Some(v) => assert(v == 1)
        None => assert(false)
    match iter.next():
        Some(v) => assert(v == 0)
        None => assert(false)
    match iter.next():
        Some(_) => assert(false)
        None => assert(true)

fn test_locals_persist_across_yield:
    var iter = two_step()
    match iter.next():
        Some(v) => assert(v == 11)
        None => assert(false)
    match iter.next():
        Some(v) => assert(v == 22)
        None => assert(false)
    match iter.next():
        Some(_) => assert(false)
        None => assert(true)

fn test_generator_is_iterable:
    var sum = 0
    for n in countdown(4):
        sum += n
    assert(sum == 10)

fn test_ref_capturing_generator_used_in_scope:
    let values: Vec[i32] = [4, 5, 6]
    var iter = values_from(&values)
    match iter.next():
        Some(v) => assert(v == 4)
        None => assert(false)
    match iter.next():
        Some(v) => assert(v == 5)
        None => assert(false)

fn test_ref_capturing_generator_return_propagates_ephemeral:
    let values: Vec[i32] = [7, 8]
    var iter = forward_values_from(&values)
    match iter.next():
        Some(v) => assert(v == 7)
        None => assert(false)
    match iter.next():
        Some(v) => assert(v == 8)
        None => assert(false)

fn main:
    test_next_resumes_from_each_yield()
    test_locals_persist_across_yield()
    test_generator_is_iterable()
    test_ref_capturing_generator_used_in_scope()
    test_ref_capturing_generator_return_propagates_ephemeral()
    print("ok")
