// Negative control for the unchecked domain of Span.len.

use std.builtins.print_i32

type Span {
    file: i32,
    start: i32,
    end: i32,
}

impl Span:
    fn len() -> i32:
        self.end - self.start

fn main:
    let invalid = Span { file: 0, start: -2147483647 - 1, end: 2147483647 }
    print_i32(invalid.len())
