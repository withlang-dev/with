//! expect-stdout: ok 6
//! expect-stdout: block 42
//! expect-stdout: err true
//! expect-stdout: some 8

// §9.1 / D60 with §4.9: under `-> Result[T, E]` the tail assignment yields a
// read of its place, and a read of type `T` is wrapped in `Ok` like any
// other tail of type `T`. An early `return Err(..)` does not make the tail a
// missing return: the tail is a value.

error E = Bad

var g: i32 = 5

fn res_i32 -> Result[i32, E]: g += 1

fn res_block(fail: bool) -> Result[i32, E]:
    if fail: return Err(.Bad)
    g = 42

fn opt_i32 -> Option[i32]:
    var o: Option[i32] = None
    o = Some(8)

fn main:
    print(f"ok {res_i32() ?? -1}")
    print(f"block {res_block(false) ?? -1}")
    print(f"err {res_block(true).is_err()}")
    print(f"some {opt_i32() ?? -1}")
