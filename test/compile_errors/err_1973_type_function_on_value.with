//! expect-error: 'Item.tag' is a function of the type and takes no receiver; call it as `Item.tag(...)`

// #1973: `fn Item.tag()` at top level is a function of the type, with no
// receiver (functions.md, D7). Called through a value, the value had no
// parameter to fill: MIR passed it anyway and LLVM verification failed.
pub type Item { x: i64 }
pub fn Item.tag() -> str: "a"

fn main:
    let i = Item { x: 1 }
    print(Item.tag())
    print(i.tag())
