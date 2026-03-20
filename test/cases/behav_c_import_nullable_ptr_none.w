//! expect-stdout: ok

use c_import("stdlib.h")

pub error E = Bad

fn make_handle -> i64:
    let raw_opt = malloc(8)
    if raw_opt == None:
        return 0
    let raw = raw_opt.unwrap()
    let _ = realloc(raw, 0)
    1

fn allocish -> Result[i32, E]:
    let raw_opt = malloc(8)
    if raw_opt == None:
        return Err(.Bad)
    let raw = raw_opt.unwrap()
    let _ = realloc(raw, 0)
    Ok(1)

fn main:
    assert(make_handle() == 1)
    let result = allocish()
    let value = match result
        .Ok(v) => assert(v == 1)
        .Err(_) => assert(false)
    let _ = value
    println("ok")
