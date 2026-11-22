//! expect-stdout: 42 0

use std.sync

type Issue546Guard {
    value: i32,
}

impl Scoped[i32] for Issue546Guard:
    fn with_enter(self: &Self) -> i32:
        self.value

    fn with_exit(self: &Self) -> Unit:
        return

fn issue546_find(flag: bool) -> i32:
    let guard = Issue546Guard { value: 42 }
    with guard as data:
        if flag:
            return data
    0

fn main:
    print(f"{issue546_find(true)} {issue546_find(false)}")
