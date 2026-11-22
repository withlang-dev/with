//! expect-stdout: 42

// §12.4 (#1598): a local used only inside an `unsafe` block is captured.
fn run(f: fn() -> i32) -> i32: f()
fn main:
    var slot: i32 = 0
    let p = &raw mut slot
    run(() =>
        unsafe { *p = 42 }
        0
    )
    print(slot)
