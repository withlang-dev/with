fn passthrough(@[noalias] p: *mut i32) -> *mut i32:
    p

fn main() -> i32:
    var x = 7
    let p = passthrough((&raw mut x) as *mut i32)
    if p == null:
        return 1
    0
