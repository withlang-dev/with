//! args: --validate-all
//! expect-check-stdout: validate-all: ok

fn mixed(x: i32) -> i32:
    match x:
        0 => {
            return 1
        }
        _ => 2

fn all_diverge(x: i32) -> i32:
    match x:
        0 => {
            return 3
        }
        _ => {
            return 4
        }

fn main:
    let _ = mixed(0)
    let _ = all_diverge(1)
