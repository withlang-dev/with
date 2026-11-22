//! args: --dump-typed
//! expect-check-stdout: bind i: i32
//! expect-check-stdout-not: expr binary span=24240..24274 : str

// Frontend has an annotated top-level string literal. Its interned string key
// used to be recorded as an AST node type and collided with AstPool.file's
// integer comparison in the merged compiler-module pool.
use compiler.Frontend
use std.builtins.print_i32

fn main: print_i32(0)
