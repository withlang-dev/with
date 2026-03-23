fn passthrough(@[noalias] p: *mut i32) -> *mut i32:
    p

fn main() -> i32:
    let mut x = 7
    let p = passthrough((&mut x) as *mut i32)
    if p == null:
        return 1
    0
