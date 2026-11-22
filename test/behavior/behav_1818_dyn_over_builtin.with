//! expect-stdout: abc!
//! expect-stdout: int 7
//! expect-stdout: abc
//! expect-stdout: 7
//! expect-stdout: abc!

// #1818 (§11 trait objects): a `str` or integer place coerces to `&dyn
// Trait` like a struct does: the fat pointer carries the value's address
// and the impl's vtable. Codegen found no concrete type for a builtin and
// aborted in the fn-value adapter.
use std.traits

trait Speak:
    fn say(self: &Self) -> str

impl Speak for str:
    fn say(self: &Self) -> str: self ++ "!"

impl Speak for i32:
    fn say(self: &Self) -> str: f"int {*self}"

fn show_dyn(d: &dyn Speak): print(d.say())

fn show_display(d: &dyn Display): print(d.to_str())

fn main:
    let a = "abc"
    show_dyn(&a)
    let n: i32 = 7
    show_dyn(&n)
    show_display(&a)
    show_display(&n)
    let d: &dyn Speak = &a
    print(d.say())
