// T23/#988 fail-late: unannotated impl method defers to inference
// (contract check skipped without annotation, :2024); inferred i32 matches.
// Expect check PASS.
use std.builtins.int_to_string

trait Getter:
    fn get(self: &Self) -> i32

type Box { x: i32 }

impl Getter for Box:
    fn get(self: &Self):
        self.x

fn main:
    let b = Box { x: 41 }
    print(int_to_string(b.get() + 1))
