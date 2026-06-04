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

fn main:
    test_next_resumes_from_each_yield()
    test_locals_persist_across_yield()
    test_generator_is_iterable()
    print("ok")
