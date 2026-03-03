type Pair = { x: i32, y: i32 }

fn main -> i32:
    var p = Pair { x: 1, y: 2 }
    let all = &mut p
    let fx = &p.x
    let _k = all.y
    *fx
