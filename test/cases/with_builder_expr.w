// Test: with Form 2 returns tail expression when non-Unit
type Box = {
    x: i32,
}

fn main -> i32:
    let v = with Box { x: 1 } as mut b:
        b.x = 9
        b.x + 33

    assert(v == 42)
