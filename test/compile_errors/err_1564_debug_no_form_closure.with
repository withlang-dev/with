//! expect-check-fail: cannot format a value of type 'fn(i32) -> isize' with :? — §15.4.7 gives it no Debug form

// D71 / §15.4.7 (#1564): a closure has no Debug form; `:?` on one is a
// compile error naming its type, never a placeholder.

fn main:
    let base = 3
    let add = (x: i32) => x + base
    print(f"{add:?}")
