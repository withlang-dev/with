//! expect-debug-alloc: leak count=0
//! expect-stdout: hi there!
//! expect-stdout: 3
//! expect-stdout: 2
//! expect-stdout: drop shared
//! expect-stdout: done

// #983, D63: a `move` closure owns its captures in a heap cell, and the
// cell's drop drops them; an Rc's last holder drops its payload.
use std.rc

type Noisy:
    name: str

impl Drop for Noisy:
    move fn drop():
        print(f"drop {self.name}")

fn main:
    let greeting = "hi " ++ "there"
    let words = ["a" ++ "", "b" ++ "", "c" ++ ""]
    let shout = move () => greeting ++ "!"
    let count = move () => words.len()
    print(shout())
    print(count())
    let first = Rc.new(Noisy { name: "shared" ++ "" })
    let second = first.clone()
    print(second.strong_count())
    drop(first)
    drop(second)
    print("done")
