//! expect-stdout: ok

global var counter: i32 = 0

fn bump:
    counter = counter + 1

fn main:
    counter = 0
    bump()
    bump()
    assert(counter == 2)
    print("ok")
