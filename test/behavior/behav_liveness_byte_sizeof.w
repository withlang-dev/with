//! expect-stdout: fd 8 fd_unit 4
//! expect-stdout: two 12
//! expect-stdout: text 24 items 40 boxed 16
//! expect-stdout: handle 8 named 24
//! expect-stdout: ok

// §2.5.1 / D72 (#1431): the hidden liveness byte is added only to a `Drop`
// struct whose all-zero storage can be a live value; a struct with no Drop
// impl keeps its size. D82 (#1944): an owning field (a str, a Vec, a Box)
// can be vacated by an explicit `move v.field` while `v` stays live, so its
// all-zero storage IS a live value and the struct carries the byte (and its
// alignment padding) too; only a field no vacate can zero — a raw pointer,
// a reference, an extern callable, a view — keeps the storage test.

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

type Handle { p: *mut u8 }
impl Drop for Handle:
    move fn drop(): print("x")

type Named { p: *mut u8, name: str }
impl Drop for Named:
    move fn drop(): print("x")

fn main:
    print(f"fd {size_of[Fd]()} fd_unit {size_of[FdUnit]()}")
    print(f"two {size_of[Two]()}")
    print(f"text {size_of[Text]()} items {size_of[Items]()} boxed {size_of[Boxed]()}")
    print(f"handle {size_of[Handle]()} named {size_of[Named]()}")
    print("ok")
