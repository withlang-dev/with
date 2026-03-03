type Pair = { x: i32, y: i32 }

fn main -> i32:
    var p = Pair { x: 1, y: 2 }
    let rx = &p.x
    let ry = &mut p.y
    *ry = *ry + 1
    *rx + *ry
