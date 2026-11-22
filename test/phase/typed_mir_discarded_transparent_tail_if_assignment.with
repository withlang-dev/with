//! args: --validate-all
//! expect-check-stdout: validate-all: ok

fn grouped_assignment():
    var value = 0
    (if true: value = 1)

fn unsafe_assignment():
    var value = 0
    unsafe:
        let ptr = &raw mut value
        if true:
            *ptr = 1

fn no_suspend_assignment():
    var value = 0
    no_suspend:
        if true:
            value = 1

fn main:
    grouped_assignment()
    unsafe_assignment()
    no_suspend_assignment()
