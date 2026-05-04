//! expect-check-pass

fn main:
    var x = 0

    // defer: inline colon
    defer: x = x + 1

    // errdefer: inline colon
    errdefer: x = x + 2

    // defer indented colon
    defer:
        x = x + 3

    // errdefer indented colon
    errdefer:
        x = x + 4

    // defer braced
    defer { x = x + 5 }

    // errdefer braced
    errdefer { x = x + 6 }
