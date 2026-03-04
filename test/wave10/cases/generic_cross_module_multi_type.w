// Wave 10: cross-module monomorphization for distinct type arguments.

use mono.shared

fn main -> i32:
    let a = id(1)
    let b = id(true)
    if a == 1 and b then 0 else 1
