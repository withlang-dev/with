//! check-only
//! args: --no-std
// §18.7: raw pointers and slices work under --no-std.
@[panic_handler]
fn on_panic -> Never:
    unreachable()

@[entry]
fn start -> i32:
    let a = [10, 20, 30, 40]
    let s: []i32 = a[1..3]
    var sum = 0
    for x in s:
        sum = sum + x
    var m = [1, 2, 3]
    let p = &raw mut m[0]
    let addr = p as usize
    let q = addr as *mut i32
    unsafe:
        *q = 99
    sum + m[0]
