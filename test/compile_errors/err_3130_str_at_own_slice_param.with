//! expect-check-fail: argument expression 'text' has type str

// #3130 (§16.2b.8): the rule is a contract's. A `[]u8` parameter of the
// program's own function takes bytes; text is spelled `text.as_bytes()`.
fn total(bytes: []u8) -> i32:
    var t = 0
    for b in bytes: t += b as i32
    t

fn main:
    let text = "abc"
    print(total(text))
