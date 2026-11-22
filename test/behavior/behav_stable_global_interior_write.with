//! expect-stdout: 9 2
//! expect-stdout: 4 4
//! expect-stdout: 9

// §9.1c: a stable (`let`) global cannot be rebound, but its value may
// mutate in place — through IndexPlace writes, `mut self` methods, and
// field assignment. Its storage is therefore writable static data, never
// an LLVM constant. Before this, codegen marked every stable global
// constant: an element or field write was silently lost (the read folded
// to the initializer) and a `push` wrote the header into a read-only page
// (a bus error). D119 step 3 made the List case load-bearing: a migrated
// C file-scope array is a stable List global (C cannot assign an array),
// so its elements must stay writable.

use std.collections

let table: List[i32] = [1, 2, 3]

type Point:
    x: i32

let origin = Point { x: 1 }

fn main:
    table[0] = 9
    print(f"{table[0]} {table[1]}")
    table.push(4)
    print(f"{table.len()} {table[3]}")
    origin.x = 9
    print(f"{origin.x}")
