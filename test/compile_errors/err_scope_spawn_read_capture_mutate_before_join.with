//! expect-check-fail: cannot mutate `value` before scoped thread worker joins

fn main:
    var value = 40
    scope s =>:
        let handle = s.spawn(() => value + 2)
        value = 1
        let _ = handle.join()
