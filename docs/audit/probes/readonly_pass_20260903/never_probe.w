use std.builtins.print
fn die(msg: str) -> Never:
    panic(msg)
fn main:
    print("before")
    die("boom")
    print("after-unreachable")
