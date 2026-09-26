//! expect-stdout: 2
//! expect-stdout: ab

// §12.4: a closure created inside another closure captures the enclosing
// closure's capture by place — the place it points at, not the slot that
// holds the pointer. The inner write used to land in the slot (the count
// stayed 0) and a str capture crashed.
fn run(f: fn(i32) -> bool) -> bool: f(1)

fn main:
    var total = 0
    var s = "a"
    let _ = run(x => run(y => {
        total += x + y
        s = s ++ "b"
        true
    }))
    print(total)
    print(s)
