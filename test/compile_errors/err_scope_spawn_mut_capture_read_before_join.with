//! expect-check-fail: scoped thread worker mutably captures `value`

fn main:
    var value = 40
    scope s =>:
        let handle = s.spawn(() => { value = value + 2; 0 })
        let seen = value
        let _ = handle.join()
        let _ = seen
