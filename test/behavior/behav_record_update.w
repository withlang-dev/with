//! expect-stdout: ok

// Behavior test: record update syntax { expr with field: val }

type Config {
    width: i32,
    height: i32,
    depth: i32,
}

fn test_basic_update:
    let c = Config { width: 100, height: 200, depth: 50 }
    let c2 = { c with width: 300 }
    assert(c2.width == 300)
    assert(c2.height == 200)
    assert(c2.depth == 50)

fn test_update_multiple_fields:
    let c = Config { width: 10, height: 20, depth: 30 }
    let c2 = { c with width: 100, height: 200 }
    assert(c2.width == 100)
    assert(c2.height == 200)
    assert(c2.depth == 30)

fn main:
    test_basic_update()
    test_update_multiple_fields()
    print("ok")
