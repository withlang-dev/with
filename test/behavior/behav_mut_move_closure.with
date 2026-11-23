// Test: move closure semantics (§9.4 / §15.9)

fn apply(f: fn(i32) -> i32, x: i32) -> i32: f(x)
fn run(f: fn() -> i32) -> i32: f()

// Case 1: move closure mutates captured copy — no §15.9 error
fn test_move_mutates_copy:
    var x = 10
    let result = apply(
        move (n: i32) =>
            x = x + n
            x
        , 5)
    assert(result == 15)
    assert(x == 10)

// Case 3: view-liveness — move closure doesn't register borrows
fn test_move_no_borrow_conflict:
    var x = 42
    let r = &x
    let result = run(
        move () =>
            var y = x
            y = y + 1
            y
        )
    assert(*r == 42)
    assert(result == 43)

// Case 4: non-move escaping closure that does NOT mutate still works
fn test_non_move_read_only:
    var x = 10
    let result = run(
        () =>
            x
        )
    assert(result == 10)
