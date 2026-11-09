//! expect-stdout: 7 1

// #3187: the same through a user module's generic method (lib/pair_3187.w
// binds `let i`): the program's top-level `var i` reaches its helper `show`
// (D184), and the instance of `Pair.first` that `show` triggers is checked
// with the script mark kept, so its `let i` is no shadowing.
use lib.pair_3187

fn show(p: &Pair[i32]) -> i32: p.first() + 0

var i = 1
print(f"{show(&Pair { a: 7, b: 8 })} {i}")
