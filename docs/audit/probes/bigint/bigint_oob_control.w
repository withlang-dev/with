// Negative control: indexed array OOB must fail closed (panic), proving that
// the from_monty risk class is about RAW-pointer writes (which bypass checks),
// not indexed access.
use std.builtins.print

fn main:
    var a: [u32; 80] = [0u32; 80]
    var idx = 100
    a[idx] = 1u32
    print("no-panic-unexpected")
