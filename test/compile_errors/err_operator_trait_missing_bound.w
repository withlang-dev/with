//! expect-check-fail: does not implement trait 'Add'

type Plain { value: i32 }

fn add_value[T: Add[T, T]](left: T, right: T) -> T:
    left.add(right)

fn main:
    add_value(Plain { value: 1 }, Plain { value: 2 })
