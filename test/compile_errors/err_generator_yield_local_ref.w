//! expect-check-fail: yielded view may outlive its origin

gen fn bad -> &i32:
    let value = 42
    let view = &value
    yield view
