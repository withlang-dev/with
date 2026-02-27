// Struct pattern matching
type Point = { x: i32, y: i32 }

fn classify(p: Point) -> i32:
    match p
        { x: 0, y: 0 } -> 0
        { x: 0, y } -> y
        { x, y: 0 } -> x
        { x, y } -> x + y

fn main -> i32:
    let origin = Point { x: 0, y: 0 }
    let on_y = Point { x: 0, y: 5 }
    let on_x = Point { x: 3, y: 0 }
    let other = Point { x: 2, y: 3 }

    var result = 0
    if classify(origin) != 0: result = result + 1
    if classify(on_y) != 5: result = result + 1
    if classify(on_x) != 3: result = result + 1
    if classify(other) != 5: result = result + 1

    println(result)
    result
