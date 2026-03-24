type Point { x: i32, y: i32 }

fn add(
    x: i32,
    y: i32,
) -> i32:
    x + y

fn apply(
    callback: fn(
        i32,
        i32,
    ) -> i32,
    data: [
        u8;
        4
    ],
) -> i32:
    let first = data[
        0
    ] as i32
    callback(
        100,
        200,
    ) + first

fn main:
    let pair = (
        7,
        9,
    )
    let nums = [
        3 as u8,
        4 as u8,
        5 as u8,
        6 as u8,
    ]
    let p = Point {
        x: add(
            pair.0,
            pair.1,
        ),
        y: apply(
            add,
            nums,
        ),
    }
    assert(p.x == 16)
    assert(p.y == 303)
