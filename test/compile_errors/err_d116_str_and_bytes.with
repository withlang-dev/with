//! expect-error: `++` concatenates two sequences, or two `str`

// D116 (§15.4.9): a `str` is text, not a byte sequence; it does not
// concatenate with a List.
fn main:
    let s = "ab" ++ [1, 2]
    print(s)
