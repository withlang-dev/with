use std.builtins.print_i32

@[target("x86_64")]
fn selected_arch() -> i32: 86

@[target("aarch64")]
fn selected_arch() -> i32: 64

fn main:
    print_i32(selected_arch())
