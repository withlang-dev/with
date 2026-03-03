type Pair = { x: i32, y: i32 }

fn main -> i32:
    var p = Pair { x: 1, y: 2 }
    let rx = &p.x
    let mx = &mut p.x
    *rx + *mx
