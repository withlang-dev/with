//! expect-check-fail: unknown field 'max' for type 'str'

// #3441: only a numeric type has `min` and `max`.
fn main:
    print(str.max)
