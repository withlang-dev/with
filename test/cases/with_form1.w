// Test: with block form 1 (guarded/binding with scope)
type Counter = { value: i32 }

fn make_counter(n: i32) -> Counter =
    Counter { value: n }

fn main() -> i32 =
    with make_counter(42) as c:
        if c.value == 42 then 0 else 1
