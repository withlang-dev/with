//! expect-stdout: ok

// Test: require and check are available from prelude without imports.
// Test: require(true, ...) and check(true, ...) do not panic.

fn main:
    // require(true) does not panic
    require(true, "this should not fire")

    // check(true) does not panic
    check(true, "this should not fire either")

    // assert still works
    assert(true)

    // All three are available without use (prelude)
    print("ok")
