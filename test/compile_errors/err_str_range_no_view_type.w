//! expect-check-fail: a range of a str has no view type yet

// #1587: `s[2..]` used to reach MIR as a valueless expression; until a str
// range has a view type it is refused with the spellings that exist.
fn main:
    let s = "hello"
    let t: str = s[2..]
    print(t)
