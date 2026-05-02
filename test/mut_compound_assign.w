// Test: §6.3 compound assignment single-evaluation

var counter_state: i32 = 0

fn counter() -> i32:
    counter_state = counter_state + 1
    counter_state - 1

fn test_compound_assign_single_eval:
    counter_state = 0
    var xs = Vec.new()
    xs.push(10)
    xs.push(20)
    xs.push(30)
    // xs[counter()] += 1 should call counter() exactly once
    xs[counter()] += 1
    assert(counter_state == 1)
    assert(xs.get(0) == 11)
    assert(xs.get(1) == 20)
    assert(xs.get(2) == 30)

fn test_compound_assign_variable_index:
    var xs = Vec.new()
    xs.push(100)
    xs.push(200)
    var i = 1
    xs[i] += 50
    assert(xs.get(0) == 100)
    assert(xs.get(1) == 250)
