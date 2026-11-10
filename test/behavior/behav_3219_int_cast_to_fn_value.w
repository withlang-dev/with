//! expect-stdout: 4096 0

// #3219: an integer cast to a function type is a function value: the code
// address and no context. A local bound to one and called directly emitted
// `call i32 4096(i32 1)` ("Called function must be a pointer"); the value
// was never made a function value at all. The program does not call it: it
// reads the two words back.
fn words_of(f: fn(i32) -> i32) -> [usize; 2]: unsafe { transmute[[usize; 2]](f) }

fn main:
    let f = unsafe { 4096 as fn(i32) -> i32 }
    let words = words_of(f)
    print(f"{words[0]} {words[1]}")
