//! expect-error: the initializer of global `count` reads `table`, declared after it: a module's initializers run in declaration order (§9.1c)
// §9.1c: a module's initializers run in declaration order, so `table` has
// no value yet when `count`'s runs. (Untyped, this was an internal error
// in codegen; typed, the program read the zeroed storage.)
let count: u64 = (table.len() as u64)
let table = [1, 2, 3]

fn main:
    print(f"{count}")
