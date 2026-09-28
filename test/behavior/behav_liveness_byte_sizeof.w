//! expect-stdout: fd 8 fd_unit 4
//! expect-stdout: two 12
//! expect-stdout: text 16 items 32 boxed 8
//! expect-stdout: ok

// §2.5.1 / D72 (#1431): the hidden liveness byte is added only to a `Drop`
// struct whose all-zero storage can be a live value; a struct with an owning
// non-null field (a str, a Vec, a Box), and a struct with no Drop impl, keep
// their size.

use std.box.Box

type Fd { n: i32 }
impl Drop for Fd:
    move fn drop(): print("x")

type FdUnit { n: i32 }

type Two { a: i32, b: i32 }
impl Drop for Two:
    move fn drop(): print("x")

type Text { s: str }
impl Drop for Text:
    move fn drop(): print("x")

type Items { v: Vec[i32] }
impl Drop for Items:
    move fn drop(): print("x")

type Boxed { b: Box[i32] }
impl Drop for Boxed:
    move fn drop(): print("x")

fn main:
    print(f"fd {size_of[Fd]()} fd_unit {size_of[FdUnit]()}")
    print(f"two {size_of[Two]()}")
    print(f"text {size_of[Text]()} items {size_of[Items]()} boxed {size_of[Boxed]()}")
    print("ok")
