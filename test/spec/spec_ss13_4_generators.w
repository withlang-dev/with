//! expect-stdout: ok
// Spec test: Section 13.4 — Generators (D69: a `for` over a generator runs
// its body at each `yield`, inside the generator's call).

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

gen fn upto(count: i32) -> i32:
    for i in 0..count:
        yield i * 10

fn test_body_runs_at_each_yield:
    var seen: Vec[i32] = Vec.new()
    for v in countdown(3):
        seen.push(v)
    assert(seen.len() == 4)
    assert(seen[0] == 3 and seen[1] == 2 and seen[2] == 1 and seen[3] == 0)

fn test_locals_persist_across_yield:
    var seen: Vec[i32] = Vec.new()
    for v in two_step():
        seen.push(v)
    assert(seen.len() == 2)
    assert(seen[0] == 11 and seen[1] == 22)

fn test_generator_is_iterable:
    var sum = 0
    for n in countdown(4):
        sum += n
    assert(sum == 10)

fn test_for_in_generator_keeps_its_counter:
    var sum = 0
    for v in upto(4):
        sum += v
    assert(sum == 60)

fn test_calling_runs_nothing_until_consumed:
    let g = countdown(2)
    var sum = 0
    for v in g:
        sum += v
    assert(sum == 3)

fn test_break_stops_the_generator:
    var seen = 0
    for v in countdown(100):
        seen += 1
        if v == 98: break
    assert(seen == 3)

fn test_ref_capturing_generator_used_in_scope:
    let values: Vec[i32] = [4, 5, 6]
    var sum = 0
    for v in values_from(&values):
        sum += v
    assert(sum == 15)

fn test_ref_capturing_generator_return_propagates_ephemeral:
    let values: Vec[i32] = [7, 8]
    var sum = 0
    for v in forward_values_from(&values):
        sum += v
    assert(sum == 15)

fn main:
    test_body_runs_at_each_yield()
    test_locals_persist_across_yield()
    test_generator_is_iterable()
    test_for_in_generator_keeps_its_counter()
    test_calling_runs_nothing_until_consumed()
    test_break_stops_the_generator()
    test_ref_capturing_generator_used_in_scope()
    test_ref_capturing_generator_return_propagates_ephemeral()
    print("ok")
