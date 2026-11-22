//! expect-error: bind `total` before the block to use it after it

// A binding made inside a block is gone after it; the error names where it
// was bound instead of suggesting a different name.

fn main:
    let items = [1, 2, 3]
    for x in items:
        let total = x * 2
    print(total)
