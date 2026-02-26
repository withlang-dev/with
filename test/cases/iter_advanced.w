// Test: Advanced iterator patterns
// Tests break/continue in iterators, early termination, and find-first patterns

type Range = {
    current: i32,
    end_val: i32
}

impl Range =
    fn next(self: *mut Range) -> ?i32:
        if self.current < self.end_val:
            let v = self.current
            self.current = self.current + 1
            Some(v)
        else
            None

// Find first element matching a condition (first even > 4)
fn find_first_even_gt4 -> i32:
    var r = Range { current: 0, end_val: 20 }
    var result = -1
    for x in r:
        if x > 4 and x % 2 == 0:
            result = x
            break
    result

// Take-while pattern: sum while < 10
fn sum_while_lt10 -> i32:
    var r = Range { current: 1, end_val: 100 }
    var acc = 0
    for x in r:
        if x >= 10:
            break
        acc = acc + x
    acc

// Skip pattern using continue
fn sum_skip_multiples_of_3 -> i32:
    var r = Range { current: 1, end_val: 10 }
    var acc = 0
    for x in r:
        if x % 3 == 0:
            continue
        acc = acc + x
    acc

// Enumerate pattern: find index of first value > 7
fn index_of_gt7 -> i32:
    var r = Range { current: 3, end_val: 15 }
    var idx = 0
    var found_idx = -1
    for x in r:
        if x > 7 and found_idx == -1:
            found_idx = idx
        idx = idx + 1
    found_idx

// Collect to array pattern
fn sum_first_n(n: i32) -> i32:
    var r = Range { current: 0, end_val: 100 }
    var count = 0
    var acc = 0
    for x in r:
        if count >= n:
            break
        acc = acc + x
        count = count + 1
    acc

fn main -> i32:
    // Find first even number > 4 → 6
    assert(find_first_even_gt4() == 6)

    // Sum while < 10 → 1+2+3+4+5+6+7+8+9 = 45
    assert(sum_while_lt10() == 45)

    // Sum 1..9 skipping multiples of 3 → 1+2+4+5+7+8 = 27
    assert(sum_skip_multiples_of_3() == 27)

    // Index of first value > 7 in [3,4,5,6,7,8,...] → index 5 (value 8)
    assert(index_of_gt7() == 5)

    // Sum first 5 values of 0..100 → 0+1+2+3+4 = 10
    assert(sum_first_n(5) == 10)

    // Sum first 0 values → 0
    assert(sum_first_n(0) == 0)

    println("all advanced iterator tests passed")
