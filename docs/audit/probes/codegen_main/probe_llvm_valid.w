type Pt { x: i32, y: i32 }

fn get_x(p: Pt) -> i32:
    p.x

fn maybe_add(a: i32) -> Option[i32]:
    if a > 0:
        Some(a + 1)
    else:
        None

fn main -> i32:
    let p = Pt { x: 10, y: 20 }
    let m = maybe_add(5)
    if get_x(p) == 10 and m == Some(6) and maybe_add(-1) == None:
        0
    else:
        1
