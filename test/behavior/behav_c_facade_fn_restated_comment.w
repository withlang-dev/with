//! expect-stdout: after pure: 2
//! expect-stdout: ok

// A restated item is the same words whatever follows it: an item ends with
// its last clause, never with the layout newlines after it, so a comment
// between the item and the next declaration is not part of its contract
// (the runtime's fiber_stubs and fiber_runtime blocks both name
// `rt_libc_abort`; one is followed by a comment, and the wasm32 runtime
// bundle compiles both in one unit).

use c_import("c_facade_text.h")

c facade notes:
    domain errno thread
    fn note_pure
        preserves domain errno

// This comment sits between the two restatements.
fn helper() -> i32: 1

c facade notes_again:
    domain errno thread
    fn note_pure
        preserves domain errno

fn main:
    let two = note_pure(helper())
    print(f"after pure: {two}")
    print("ok")
