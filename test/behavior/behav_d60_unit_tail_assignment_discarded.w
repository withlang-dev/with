//! expect-stdout: g 8
//! expect-stdout: default 0
//! expect-stdout: unsafe g 9

// §9.1 / D60, D43: with no declared return or `-> Unit`, a body's own tail
// assignment is a statement: the body is `Unit`, in every body spelling —
// single statement, block, and the source body of an `unsafe fn` (its
// implicit unsafe wrapper is not a second body). §4.10's implicit default
// applies only to a `Unit` tail, such as a call.

var g: i32 = 0
var log: i32 = 0

fn unit_decl -> Unit: g += 1
fn unit_block -> Unit:
    let a = 3
    g = a
fn unannotated: g += 1
fn unannotated_block:
    let a = 2
    g *= a
unsafe fn unsafe_unannotated(p: *mut i32): *p = 9
unsafe fn unsafe_unannotated_block(p: *mut i32):
    let v = 9
    *p = v

fn note(x: i32): log += x

// A Unit call tail under `-> i32` is the implicit default (§4.10).
fn defaulted -> i32: note(1)

fn main:
    unit_decl()
    unit_block()
    unannotated()
    unannotated_block()
    print(f"g {g}")
    print(f"default {defaulted()}")
    let r: Unit = unsafe { unsafe_unannotated(&raw mut g) }
    let r2: Unit = unsafe { unsafe_unannotated_block(&raw mut g) }
    print(f"unsafe g {g}")
