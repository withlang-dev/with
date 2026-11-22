//! args: --validate-all
//! expect-check-stdout: validate-all: ok

use std.builtins.print_i32

fn advance():
    let _ = 0

fn choose(flag: bool) -> i32:
    if flag:
        advance()
        return 1
    else:
        advance()
        return 2

fn main: print_i32(choose(true))
